# ABSTRACT: A Selenese Test Case
package Parse::Selenese::TestCase;
use Moose;
use Carp ();
use open ':encoding(utf8)';
use Cwd;
use Encode;
use Try::Tiny;
use File::Basename;
use HTML::TreeBuilder;
use Parse::Selenese::Command;
use Parse::Selenese::TestCase;
use Text::MicroTemplate;
use Template;
use File::Temp;
use HTML::Element;
use MooseX::AttributeShortcuts;

our $VERSION = '0.006'; # VERSION

my ( $_test_mt, $_selenese_testcase_template, $_selenese_testcase_template2 );

has 'commands' => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 0,
    default  => sub { [] }
);

has [ qw/ content filename / ] => (
    isa       => 'Str',
    is        => 'rw',
    required  => 0,
    clearer   => 1,
    predicate => 1,
);
has [ qw/ path base_url title thead / ] => (
    isa       => 'Str',
    is        => 'rw',
    required  => 0,
);

has [ qw/ title thead / ] => (
    isa        => 'Str',
    is         => 'ro',
    clearer    => 1,
    lazy_build => 1,
);

has 'result' => (
    isa => 'Str',
    is  => 'ro',
    lazy_build => 1,
);

has 'log' => (
    isa => 'Str',
    is  => 'rw',
);

has '_tree' => (
    isa        => 'HTML::TreeBuilder',
    is         => 'ro',
    clearer    => 1,
    lazy_build => 1,
);

has [qw/ command_passes command_failures /] => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_command_passes {
    my $self = shift;
    return grep { $_->result =~ /passed|done/ } @{ $self->commands };
}

sub _build_command_failures {
    my $self = shift;
    #warn defined $_->has_result for @{ $self->commands };
    return grep { $_->result !~ /passed|done/ } @{ $self->commands };
    return grep { defined $_->has_result } @{ $self->commands };
}

sub _build_result {
    my $self = shift;
    my ($result) = $self->_tree->look_down( '_tag', 'tr', 'class', qr/title/ )->attr('class') =~ /status_(.*)/;
    return $result;
}

sub _build__tree {
    my $self = shift;
    my $tree = HTML::TreeBuilder->new;
    $tree->store_comments(1);
    return $tree;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( filename => $_[0], )
          if defined $_[0]
              && defined Cwd::abs_path( $_[0] )
              && -e Cwd::abs_path( $_[0] );
        return $class->$orig( content => $_[0], );
    }
    elsif ( @_ == 1 && ref $_[0] ) {
        return $class->$orig( commands => $_[0], );
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    $self->parse if $self->has_filename || $self->has_content;
}

sub short_name {
    my $self = shift;
    my $x    = File::Basename::basename( $self->filename );
    return ( File::Basename::fileparse( $x, qr/\.[^.]*/ ) )[0];
}

sub _build_thead {
    my $self    = shift;
    my $content = '';
    my $thead   = $self->_tree->find('thead');
    if ($thead) {
        my $td = $thead->find( 'td', rowspan => 3 );
        if ($td) {
            $content = $td->content->[0];
        }
    }
    return $content;
}

sub _build_title {
    my $self  = shift;
    my $title = try {
        $self->_tree->find('title')->content->[0];
    }
    catch {
        try {
            $self->_tree->look_down(
                '_tag' => 'a',
                'name' => qr/testresult/,
            )->as_text;
        };
    };
    return $title || '';
}

sub parse {
    my $self = shift;

    # Only parse things once
    return if scalar @{ $self->commands };

    # Dear God this shouldn't be written like this. There _MUST_ be a better
    # way...
    # HOW DO I WROTE PERL?
    #    if ( defined( $self->filename ) || !defined( $self->content ) ) {
    #        unless ( defined ($self->filename) && (-r $self->filename) ) {
    #            die "file isn't readable";
    #        }
    #    }
    #    else {
    #        die "file isn't defined";
    #    }
    if ( $self->has_filename ) {
        if ( !-r $self->filename ) {
            die "Um, I can't read the file you gave me to parse!";
        }
        $self->_tree->parse_file( $self->filename );
    }
    elsif ( $self->has_content ) {
        $self->_tree->parse( $self->content );
    }
    else {
        die "Must specifiy either content or filename";
    }

    foreach my $link ( $self->_tree->find('link') ) {
        if ( $link->attr('rel') eq 'selenium.base' ) {
            $self->base_url( $link->attr('href') );
        }
    }

    return unless my $tbody = $self->_tree->find('tbody');
    my @commands;
    foreach my $trs_comments ( $tbody->find( ( 'tr', '~comment' ) ) ) {
        my $command = Parse::Selenese::Command->new( $trs_comments );
        push( @commands, $command );
    }
    $self->commands( \@commands );
#$tree = $tree->delete;
}

sub as_perl {
    my $self = shift;

    my $perl_code = '';
    foreach my $command ( @{ $self->{commands} } ) {
        my $code = $command->as_perl;
        $perl_code .= $code if defined $code;
    }
    chomp $perl_code;

    my @args =
      ( $self->{base_url}, Text::MicroTemplate::encoded_string($perl_code) );

    my $renderer = Text::MicroTemplate::build_mt($_test_mt);
    return $renderer->(@args)->as_string;
}

sub save {
    my $self = shift;
    my $file = shift;

    my $filename = $self->filename;
    $filename = $file if $file;

    open my $fh, '>', $filename
      or die "Can't write to '$filename': $!\n";
    print $fh $self->as_html;
    close $fh;

}

sub as_html {
    my $self = shift;
    my $tt   = Template->new();

    my $output = '';
    my $vars   = {
        commands => $self->commands,
        base_url => $self->base_url,
        thead    => $self->thead,
        title    => $self->title,
    };
    $tt->process( \$_selenese_testcase_template2, $vars, \$output );
    return Encode::decode_utf8 $output;
}

$_test_mt = <<'END_TEST_MT';
? my $base_url  = shift;
? my $perl_code = shift;
#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;
use utf8;

my $sel = Test::WWW::Selenium->new( host => "localhost",
                                    port => 4444,
                                    browser => "*firefox",
                                    browser_url => "<?= $base_url ?>" );

<?= $perl_code ?>
END_TEST_MT

$_selenese_testcase_template = <<'END_SELENESE_TESTCASE_TEMPLATE';
[% FOREACH command = commands -%]
[% command.as_html %]
[% END %]
END_SELENESE_TESTCASE_TEMPLATE

$_selenese_testcase_template2 = <<'END_SELENESE_TESTCASE_TEMPLATE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head profile="http://selenium-ide.openqa.org/profiles/test-case">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="selenium.base" href="[% base_url %]" />
<title>[% title %]</title>
</head>
<body>
<table cellpadding="1" cellspacing="1" border="1">
<thead>
<tr><td rowspan="1" colspan="3">[% thead %]</td></tr>
</thead><tbody>
[% FOREACH command = commands -%]
[% command.as_html %][% END %]</tbody></table>
</body>
</html>
END_SELENESE_TESTCASE_TEMPLATE

1;


=pod

=head1 NAME

Parse::Selenese::TestCase - A Selenese Test Case

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Parse::Selenese::TestCase;
  my $testcase = Parse::Selenese::TestCase->new(filename => $some_file_name);
  my $testcase = Parse::Selenese::TestCase->new(content => $string);

  $testcase->as_perl; # Turn the case into Perl.
  warn "Has an open" if grep { $_->name } @{ $testcase->commands };

=head1 DESCRIPTION

Parse::Selenese::TestCase is a representation of a Selenium Selenese Test Case.

=head2 Functions

=over

=item C<BUILD>

Moose method that runs after object initialization and attempts to parse
whatever content was provided.

=item C<as_html>

Return the test case in HTML (Selenese) format.

=item C<as_HTML>

An alias to C<as_html>

=item C<as_perl>

Return the test case as a string of Perl.

=item C<save([file_name])>

Save the test case.

=item C<short_name>

The file name of the test case.

=item C<parse>

Parse the test case from the file name or content that was previously set

=back

=head1 NAME

Parse::Selenese::TestCase

=head1 AUTHOR

Theodore Robert Campbell Jr E<lt>trcjr@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

