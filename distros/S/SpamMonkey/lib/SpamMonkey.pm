package SpamMonkey;
use UNIVERSAL::require;
use File::Path::Expand qw(expand_filename);
use URI::Find::Schemeless;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.03';

=head1 NAME

SpamMonkey - Like SpamAssassin, only not.

=head1 SYNOPSIS

  use SpamMonkey;
  my $monkey = SpamMonkey->new();
  $monkey->ready;

  for (@things) {
      my $result = $monkey->test($_);
      if ($result->is_spam) { $result->rewrite }
  }

=head1 DESCRIPTION

SpamMonkey is a general purpose spam detection suite. It borrows heavily
from SpamAssassin, but it is designed to be used for plain text as well
as email.

=cut

sub rulesets { qw(body full rawbody uri header); }

sub default_rule_dir { "/etc/mail/spamassassin/" }

=head1 CONSTRUCTOR

    SpamMonkey->new(
        rule_dir => "/etc/mail/spamassassin/"
    );

SpamMonkey by default loads up rules from F</etc/mail/spamassassin>
and then F<~/.spammonkey/user_prefs>. To override the rule directory,
specify C<rule_dir> in the constructor.

=cut

sub new { my $class = shift; bless { @_ }, $class; }

sub config_class { "SpamMonkey::Config" }
sub result_class { "SpamMonkey::Result" } # Subclassers like these

=head1 METHODS

=head2 ready

This loads up the ruleset and then prunes out rules which have no score
attached to them. You must call C<ready> before doing a test, else
you'll have no rules to test with.

=cut

sub ready {
    my $self = shift;
    $self->config_class->require;
    $self->{conf} = $self->config_class->new();

    # Read rules
    for (glob(($self->{rule_dir} || $self->default_rule_dir)."/*.cf")) {
        $self->{conf}->read($_);
    }

    my $file = expand_filename("~/.spammonkey/user_prefs");
    if (-e $file) { $self->{conf}->read($file); }

    # Delete rules with no score(!)
    for ($self->rulesets) {
        my $set = $self->{conf}{rules}{$_};
        for (keys %$set) {
            if (!exists $self->{conf}{score}{$_}
                    or !$self->{conf}{score}{$_}[0]) {
                delete $set->{$_};# warn "Killing boring rule $_";
            }
        }
    }
}

=head2 test

    $self->test(Email::MIME $mime);
    $self->test($text);

This tests an email or a piece of text using the ruleset loaded by
C<ready> and returns a C<SpamMonkey::Result> object.

=cut

sub test {
    my ($self, $text) = @_;
    $self->{result} = {};
    $self->{per_message} = {};
    if (not ref $text) { 
        $self->{text} = $text;
        $self->test_text() 
    } elsif (UNIVERSAL::isa($text, "Email::MIME")) {
        $self->{email} = $text;
        $self->test_email();
    }
    $self->result_class->require;
    bless $self->{result}, $self->result_class;
    delete $self->{per_message}; # Ready it to go again
    # Invert
    $self->{result}{monkey} = $self;
    delete $self->{result};
}

sub test_text {
    my ($self) = @_;
    my $text_r = \do{$self->{text}};
    $self->test_bodylike("rawbody",$text_r,0);
    # Munge text here
    $self->test_bodylike("body",$text_r,0);
    $self->test_uris($text_r,0);
}

sub test_email {
    my ($self) = @_;
    $self->test_headers($self->{email}, 0);
    $self->{text} = $self->{email}->body_raw;
    $self->test_bodylike("rawbody",\do{$self->{text}},0);
    my $body_r = \do{$self->{email}->body};
    if ($$body_r) {
        $self->test_bodylike("body",$body_r, 0);
    } else {
        $self->test_bodylike("body",\do{$self->{text}}, 0);
    }
    $self->test_uris(\do{$self->{text}}, 0);
}

sub test_headers {
    my ($self, $email, $scoretype) = @_;
    my $set = $self->{conf}{rules}{header};
    for my $test (keys %$set) {
        my $rule = $set->{$test};
        if ($rule->{op} eq "eval") {
              $self->match($test, $scoretype)
                  for $self->do_code_rule($rule); # Maybe more than one
          next
        }
        my $text = join "\n", $email->header($rule->{header});
        if ($rule->{header} eq "ALL") {
            $text = $email->_headers_as_string; # Urgh
        }

        if ($rule->{unset} and not $text) { $text = $rule->{unset} }
        #warn "$rule->{header}: $text $rule->{op} $rule->{re}";
        next unless $text;
        if ($rule->{op} eq "exists") {
            $self->match($test, $scoretype) if $text;
        } elsif ($rule->{op} eq "!~") { 
            if($text !~ $rule->{re}) { $self->match($test, $scoretype); }
        }  else { 
            if($text =~ $rule->{re}) { $self->match($test, $scoretype); }
        }
    }
}

sub test_bodylike {
    my ($self, $ruleset, $text, $scoretype) = @_;
    my $set = $self->{conf}{rules}{$ruleset};
    for my $test (keys %$set) {
        my $rule = $set->{$test};
        if (ref $rule eq "HASH") {
            $self->match($test, $scoretype)
                for $self->do_code_rule($rule, $text);
        } else {
            if($$text =~ $rule) { $self->match($test, $scoretype); }
        }
    }
}

sub get_uris {
    my ($self, $text_r) = @_;
    return if $self->{per_message}{uris};
    $self->{per_message}{uris}= [];
    my $finder = URI::Find::Schemeless->new( sub {
        push @{$self->{per_message}{uris}}, $_[0];
    });
    $finder->find($text_r);
}

sub uris {
    my $self = shift;
    $self->get_uris($self->{text});
    return @{$self->{per_message}{uris}};
}

sub test_uris {
    my ($self, $text_r, $scoretype) = @_;
    my $set = $self->{conf}{rules}{uri};
    $self->get_uris($text_r);
    for my $uri (@{$self->{per_message}{uris}}) {
        for my $test (keys %$set) {       
            my $rule = $set->{$test};
            if ($uri =~ $rule) { $self->match($test, $scoretype) };
        }
    }
}

sub match {
    my ($self, $test, $scoretype) = @_;
    push @{$self->{result}{matched}}, $test;
    $self->{result}{score} += $self->{conf}{score}{$test}[$scoretype];
}

sub do_code_rule {
    my ($self, $rule,$text_r) = @_;
    my ($pack, $args) = $rule->{code} =~ /(\S+)\((.*)\)$/ or die("Urgh? $rule->{code}");
    my @args = ($args =~ m/['"](.*?)['"]\s*(?:,\s*|$)/g);
    $pack = "SpamMonkey::Test::".$pack;
    $pack->require or return;
    if (!$self->{init}{$pack} and $pack->can("init")) {
        $pack->init($self->{conf});
        $self->{init}{$pack}++;
    }
    $pack->test($self, $text_r, @args);
}

=head1 AUTHOR

simon, E<lt>simon@E<gt> (please don't contact me about this module,
unless you wish to take over its maintainance, in which case upload your
own version.)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by simon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
