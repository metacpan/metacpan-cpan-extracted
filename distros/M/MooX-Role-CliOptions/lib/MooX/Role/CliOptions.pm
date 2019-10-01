package MooX::Role::CliOptions;

use 5.006;
use strict;
use warnings;

use Carp qw( croak );

use Getopt::Long v2.36 qw(GetOptionsFromArray);
use Pod::Usage;

# this could have been replaced with hand-rolled "isa" clauses, but if
# one is using Moo then the odds are good that one already has this
use Types::Standard qw( ArrayRef Bool );

use Moo::Role;

our $VERSION = '0.05';

my @options = ( 'help', 'man' );
do {
    has debug => (
        is      => 'ro',
        isa     => Bool,
        default => 1,
    );

    has verbose => (
        is      => 'ro',
        isa     => Bool,
        default => 1,
    );

    push( @options, qw( debug! verbose! ) );
} unless $ENV{MRC_NO_STDOPTS};

has argv => (
    is  => 'ro',
    isa => ArrayRef,
);

sub init {
    my $class = shift;
    my %args  = @_;

    my $argv = delete( $args{argv} ) or croak q{'argv' argument is required};
    croak q{'argv' must be an array reference'}
      unless ref($argv) && ref($argv) eq 'ARRAY';

    my $add_opts = delete( $args{add_opts} ) || [];
    croak q{'add_opts' must be an array reference'}
      unless ref($add_opts) && ref($add_opts) eq 'ARRAY';

    croak q{unknown argument supplied for 'init'} if keys(%args);

    push( @options, $_ ) for ( @{$add_opts} );

    my %values;
    GetOptionsFromArray( $argv, \%values, @options ) or _pod2usage(2);
    _pod2usage(1) if $values{help};
    _pod2usage( -exitstatus => 0, -verbose => 2 ) if $values{man};

    $values{argv} = $argv;

    do {
        # have (no)debug imply verbose if that is not not specificed.
        # This is a # personal preference based on my experience of how
        # these options are most commonly used.
        $values{verbose} ||= $values{debug}
          if defined( $values{debug} ) && !defined( $values{verbose} );
    } unless $ENV{MRC_NO_STDOPTS};

    my $app = eval { $class->new(%values); };
    do {
        print $@ . "\n";
        _pod2usage(2);
    } if $@;

    return $app;
}

# this is needed so test scripts can intercept the call to pod2usage and
# prevent the exit from happening
sub _pod2usage {
    pod2usage(@_);
}

1;    # End of MooX::Role::CliOptions
__END__

=pod

=head1 NAME

MooX::Role::CliOptions - Wrapper to simplify using Moo with Getopt::Long

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This is a minimal script that composes C<MooX::Role::CliOptions>.
  
    #!/usr/bin/perl
    package My::Moodulino;
  
    use Moo;
    with 'MooX::Role::CliOptions';
  
    # initialize script attributes/variables
    has option1 => (
        is      => 'ro',
        isa     => sub {
            die 'Illegal value for option1'
              unless $_[0] =~ /^foo|bar$/;
        },
        default => '',
    );
  
    ...
  
    # this makes the script a modulino
    do {
        my $app = __PACKAGE__->init(
            argv     => \@ARGV,
            add_opts => [ 'option1=s' ],
        );
        exit $app->run;
    } unless caller();
  
    sub run {
        my $self = shift;
  
        ...
  
        return 0;
    }
  
    1; # must be present to satisfy "require" when testing
    __END__
  
=head1 DESCRIPTION

This role was written to help standardize command line script behavior and,
if written as a modulino, greatly improve testability. It should be noted
that all example code snippets below are based on the modulino style but
the normal, non-modulino style is also supported. See the example and test
scripts in the distribution for further info if needed.

The default object created when composing this Role has the following
structure (assuming a package name of C<My::Moodulino> as above and no
additional attributes are defined in the composing class.)
  
 $VAR1 = bless( {
  'debug' => 1,
  'verbose' => 1,
  'argv' => []
 }, 'My::Moodulino' );
  
=head1 EXPORTS

None. (Not applicable in a Role.)

=head1 ATTRIBUTES

Three read-only attributes are provided for the composing package, two of
which are exposed as command line arguments and the third being created from
the final C<@ARGV> values after processing by C<Getopt::Long>.

NOTE: Both C<debug> and C<verbose> can be eliminated from the Role by setting
the environment variable C<MRC_NO_STDOPTS> to a "true" value B<before>
composing C<MooX::Role::CliOptions> into your script. This allows you to
completely remove them or redefine them to suit your needs as desired. For
example, you might want C<--debug> to be "off" by default. If you decide to
redefine them you must supply a suitable attribute in your script. This does
NOT affect the C<--help> or C<--man> command line options or the C<argv>
attribute.
  
The following example demonstrates this:
  
 #!perl!
  
 # redefine --debug to be off by default and --verbose to indicate a level
 # between 0 and 5
 BEGIN {
    $ENV{MRC_NO_STDOPTS} = 1;
 }
  
 use Moo;
 with 'MooX::Role::CliOptions';
  
 # not required but strongly recommended by ths author
 use MooX::StrictConstructor;

 has debug => (
    is => 'ro',
    default => 0,
 );
  
 has verbose => (
    is => 'ro',
    isa => sub {
        die 'illegal value for --verbose'
          unless $_[0] >= 0 && $_[0] <= 5;
    },
    default => 0,
 );
  
 do {
    my $app = __PACKAGE__->init(
        argv => \@ARGV,
        add_opts => [
            'debug',
            'verbose=i',
        ],
    );
  
    exit $app->run;
 } unless caller();
  
 ...
  
=head2 debug (Boolean read-only)

Exposed as the negatable C<--debug> command line option.

Default: Boolean TRUE (1). Is turned off with C<--nodebug> on the command
line. (Paranoia is your friend.)

Commonly used to enable diagnostic reports and/or disable potentially
dangerous operations such as database modifications.

Note: Implies the setting for C<verbose> if C<--verbose> or C<--noverbose> is
not explicitly set on the command line.

=head2 verbose (Boolean read-only)

Exposed as the negatable C<--verbose> command line option.

Typically used to add extra information to the output. Often used in
conjunction with C<--debug>.

Default: Will be the same as C<debug> if not explicitly set with either
C<--verbose> or C<--noverbose>. This behavior was chosen since that is
the most common usage pattern in the author's experience.

The most likely usage patterns would be
  
 # in a crontab where no verbose output would be desired (verbose will
 # default to OFF.)
 /my_script --nodebug
  
 # manually run from the cli where normal operation is needed and verbose
 # output is desired
 /my_script --nodebug --verbose

=head2 argv (read-only)

Returns an arrayref to the contents of C<@ARGV> after processing by
C<Getopt::Long>. This is syntactic sugar for using C<@ARGV> directly.

Default: An empty arrayref if no command line arguments other than options
recognized by C<Getopt::Long> are supplied.

=head1 OTHER COMMAND LINE OPTIONS

The following command line options are also accepted, but are not
associated with an attribute since both will cause an immediate exit via
C<Pod::Usage> after displaying the appropriate message.

=head2 --help

Will use C<pod2usage> to display the C<SYNOPSIS> or C<USAGE> POD section if
available.

=head2 --man

Will use C<pod2usage> to display the full POD if available.

=head1 METHODS

=head2 init

This is the workhorse that integrates C<Getopt::Long> with the call to the
composing package's C<new> constructor. Its return value is the resulting
object of the composing package type.

=head3 Parameters

=over 4

=item argv (required)

Typically passed in as follows:
  
 my $app = __PACKAGE__->init( argv => \@ARGV );
  
This will be passed to C<Getopt::Long> for processing. Any remaining elements
will be left in C<@ARGV>. They can also be accessed via C<$app-E<gt>argv>.

=item add_opts (optional)

You can add your own command line options by using this. Simply place the
C<Getopt::Long> specification for any additional options that you want in an
array ref as shown below and be sure to declare an attribute to hold the
option data as processed by C<Getopt::Long>. (See the example scripts to make
things clear.)
  
 # in your script
 has custom1 => (
    is => 'ro',
    isa => sub { ... },
 );
  
 do {
    my $app = __PACKAGE__->init(
        argv => \@ARGV,
        add_opts => [
            'custom1=s',
        ],
    );
    exit ($app->run || 0);
 } unless caller();
  
The above snippet would tell C<Getopt::Long> to accept a command line option
named C<custom1> that must be a string and place it in the C<custom1>
attribute that was declared. You may use any kind of C<isa> or C<coerce>
test that you deem are needed as well as a default.

=back

=head1 SEE ALSO

=over 4

=item C<examples/moodulino.pl> for a functional modulino script.

=item C<examples/myscript.pl> for a functional non-modulino script.

=back

=head1 AUTHOR

Jim Bacon, C<< <boftx at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-role-clioptions at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Role-CliOptions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Role::CliOptions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Role-CliOptions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Role-CliOptions>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MooX-Role-CliOptions>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Role-CliOptions>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jim Bacon.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
