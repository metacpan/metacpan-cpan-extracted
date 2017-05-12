package Module::Format::PerlMF_App;

use strict;
use warnings;


use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;

use Module::Format::ModuleList;

=head1 NAME

Module::Format::PerlMF_App - implements the perlmf command-line application.

=head1 VERSION

Version 0.0.7

=cut

our $VERSION = '0.0.7';

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Module::Format::PerlMF_App;

    Module::Format::PerlMF_App->new({argv => [@ARGV],})->run();

=head1 FUNCTIONS

=head2 new({argv => [@ARGV]})

The constructor - call it with the command-line options.

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init(@_);
    return $self;
}

sub _argv
{
    my $self = shift;

    if (@_) {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}


sub _init
{
    my ($self, $args) = @_;

    $self->_argv([ @{$args->{argv}} ]);

    return;
}

=head2 run

Actually run the command line application.

=cut

my %ops_to_formats =
(
    'as_rpm_colon' => 'rpm_colon',
    'rpm_colon' => 'rpm_colon',
    'as_rpm_c' => 'rpm_colon',
    'rpm_c' => 'rpm_colon',
    'as_rpm_dash' => 'rpm_dash',
    'rpm_dash' => 'rpm_dash',
    'as_rpm_d' => 'rpm_dash',
    'rpm_d' => 'rpm_dash',
    'dash' => 'dash',
    'as_dash' => 'dash',
    'colon' => 'colon',
    'as_colon' => 'colon',
    'deb' => 'debian',
    'as_deb' => 'debian',
    'debian' => 'debian',
    'as_debian' => 'debian',
);

sub run
{
    my ($self) = @_;

    my $argv = $self->_argv();

    my $op = shift(@$argv);

    if (!defined($op))
    {
        die "You did not specify any arguments - see --help";
    }

    if (($op eq "-h") || ($op eq "--help"))
    {
        pod2usage(1);
    }
    elsif ($op eq "--man")
    {
        pod2usage(-verbose => 2);
    }

    if (! exists( $ops_to_formats{$op} ))
    {
        die "Unknown op '$op'.";
    }

    my $format = $ops_to_formats{$op};

    my $delim = ' ';
    my $suffix = "\n";

    my $help = 0;
    my $man = 0;
    if (! (my $ret = GetOptionsFromArray(
        $argv,
        '0!' => sub { $delim = "\0"; $suffix = q{}; },
        'n!' => sub { $delim = "\n"; $suffix = "\n"; },
        'help|h' => \$help,
        man => \$man,
    )))
    {
        die "GetOptions failed!";
    }

    if ($help)
    {
        pod2usage(1);
    }

    if ($man)
    {
        pod2usage(-verbose => 2);
    }

    my @strings = @$argv;

    my $module_list_obj = Module::Format::ModuleList->sane_from_guesses(
        {
            values => \@strings,
        }
    );

    print join($delim, @{$module_list_obj->format_as($format)}), $suffix;

    return;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-format at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Format>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Format::PerlMF_App


You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Module-Format>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Format>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Format>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Module::Format::PerlMF_App
