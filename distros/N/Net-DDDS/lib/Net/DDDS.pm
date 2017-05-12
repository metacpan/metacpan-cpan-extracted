package Net::DDDS;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::DDDS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init();
   $self
}

sub init {}

sub rules {
	my ($self,$key) = @_;
	
	die "Must override: retrieve\n";
}

sub apply_first_rule {
	my ($self,$str) = @_;
	
	ref $self->{first_rule} eq 'CODE' ? $self->{first_rule}($str) : $str;
}

sub accept_rule {
	my ($self,$rule) = @_;
	
	die "Must override: accept_rule\n";
}

sub apply_rule {
	my ($self,$rule) = @_;
	
	die "Must override: apply_rule\n";
	
}

sub lookup {
	my ($self,$str,$key) = @_;
	
	return $self->lookup($str,$self->apply_first_rule($str)) unless $key;
	my $result;
	foreach my $rule ($self->rules($key)) {
		if ($self->accept_rule($rule)) {
			$result = $self->apply_rule($rule,$str) or next;
			
			return $result if $self->is_terminal($rule);
			return $self->lookup($str,$result);		
		}
	}
	
	undef;
}

package Net::DDDS::DNS;

use Net::DNS;
use base qw/Net::DDDS/;

sub init {
	my ($self) = @_;
	$self->{_resolver} = Net::DNS::Resolver->new();
}

sub accept_rule {
	my ($self,$rule) = @_;
	
	return undef unless ref $rule && $rule->isa('Net::DNS::RR::NAPTR');
	$rule->service =~ m{\Q$self->{service}\E};
}

sub is_terminal {
	my ($self,$rule) = @_;
	
	die "Bad rule" unless $rule->isa('Net::DNS::RR::NAPTR');
	$rule->flags =~ /$self->{terminal}/;
}

sub rules {
	my ($self,$key) = @_;
	my $result = $self->{_resolver}->query($key,'NAPTR') or return undef;
	$result->answer;
}

sub apply_rule {
	my ($self,$rule,$key) = @_;

	die "Bad rule" unless $rule->isa('Net::DNS::RR::NAPTR');
	
	die "Regexp and replacement both null: $rule\n" unless $rule->regexp || $rule->replacement;
	if ($rule->regexp) {
		my $delimc = substr($rule->regexp,0,1);
		my $mi = index($rule->regexp,$delimc,1);
		die "Bad regular expression: ".$rule->regexp."\n" if $mi == -1;
		my $ri = index($rule->regexp,$delimc,$mi+1);
		die "Bad regular expression: ".$rule->regexp."\n" if $ri == -1;
		my $match = substr($rule->regexp,1,$mi-1);
		my $repl = substr($rule->regexp,$mi+1,$ri-$mi-1);
		my $flags = substr($rule->regexp,$ri+1);
		$repl =~ s{\\([0-9]+)}{$$1}og;
		$key =~ s{$match}{$repl};
                return $key;
	} else {
		return $rule->replacement;
	}
}

package Net::DDDS::ENUM;
use base qw/Net::DDDS::DNS/;

sub enum_first_rule {
    my ($str) = @_;

    $str =~ s/[^0-9]//og;
    my $x = sprintf "%s.e164.arpa",join('.',reverse(split '',$str));
    $x;
}

sub init {
	my ($self) = @_;
	
	$self->SUPER::init();
	
	$self->{terminal} = 'u';
	$self->{service} = 'E2U+sip';
	$self->{first_rule} = \&enum_first_rule;
}

package Net::DDDS::SAMLMetadata;
use base qw/Net::DDDS::DNS/;
use URI;

sub samlmd_first_rule {
    my ($str) = @_;

    my $u = URI->new($str);
    $u->host;
}

sub init {
	my ($self) = @_;
	
	$self->SUPER::init();
	$self->{terminal} = "U";
	$self->{service} = "PID2U+http";
	$self->{first_rule} = \&samlmd_first_rule;
}

package Net::DDDS;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::DDDS - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Net::DDDS;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Net::DDDS, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Leif Johansson, E<lt>leifj@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Leif Johansson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
