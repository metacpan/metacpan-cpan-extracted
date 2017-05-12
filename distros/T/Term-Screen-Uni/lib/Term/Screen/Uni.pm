package Term::Screen::Uni::PassToHandler;
use 5.005;
use strict;
use warnings;

use Carp;

use Tie::Hash;
our @ISA = ('Tie::Hash');

$|++;

sub TIEHASH
	{
	my $storage = bless {}, $_[0];
	return $storage;
	}

sub STORE
	{
	if ($_[1] ne 'handler')
		{ $_[0]{'handler'}{$_[1]} = $_[2]; };

	$_[0]{'handler'} = $_[2];
	};

sub FETCH
	{ return (($_[1] ne 'handler') ? $_[0]{'handler'}{$_[1]} : $_[0]{'handler'}); };


package Term::Screen::Uni;

use 5.005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Term::Screen::Uni ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';


use Carp;

# Preloaded methods go here.

sub term        { return (shift(@_))->{'handler'}->term(@_); };
sub rows        { return (shift(@_))->{'handler'}->rows(@_); };
sub cols        { return (shift(@_))->{'handler'}->cols(@_); };
sub at          { return (shift(@_))->{'handler'}->at(@_); };
sub resize      { return (shift(@_))->{'handler'}->resize(@_); };
sub normal      { return (shift(@_))->{'handler'}->normal(@_); };
sub bold        { return (shift(@_))->{'handler'}->bold(@_); };
sub reverse     { return (shift(@_))->{'handler'}->reverse(@_); };
sub clrscr      { return (shift(@_))->{'handler'}->clrscr(@_); };
sub clreol      { return (shift(@_))->{'handler'}->clreol(@_); };
sub clreos      { return (shift(@_))->{'handler'}->clreos(@_); };
sub il          { return (shift(@_))->{'handler'}->il(@_); };
sub dl          { return (shift(@_))->{'handler'}->dl(@_); };
sub ic_exists   { return (shift(@_))->{'handler'}->ic_exists(@_); };
sub ic          { return (shift(@_))->{'handler'}->ic(@_); };
sub dc_exists   { return (shift(@_))->{'handler'}->dc_exists(@_); };
sub dc          { return (shift(@_))->{'handler'}->dc(@_); };
sub puts        { return (shift(@_))->{'handler'}->puts(@_); };
sub getch       { return (shift(@_))->{'handler'}->getch(@_); };
sub def_key     { return (shift(@_))->{'handler'}->def_key(@_); };
sub key_pressed { return (shift(@_))->{'handler'}->key_pressed(@_); };
sub echo        { return (shift(@_))->{'handler'}->echo(@_); };
sub noecho      { return (shift(@_))->{'handler'}->noecho(@_); };
sub flush_input { return (shift(@_))->{'handler'}->flush_input(@_); };
sub stuff_input { return (shift(@_))->{'handler'}->stuff_input(@_); };
sub cleanup     { return (shift(@_))->{'handler'}->cleanup(@_); };

sub new($)
	{
	my ($class) = @_;

	my $self = undef;

	tie(%{$self}, 'Term::Screen::Uni::PassToHandler');

	if ($^O eq 'MSWin32')
		{ $self->{'handler'} = eval 'use Term::Screen::Win32; return Term::Screen::Win32->new();'; }
	else
		{ $self->{'handler'} = eval 'use Term::Screen; return Term::Screen->new();'; };

	if (!defined($self->{'handler'}))
		{ croak("Can not create Term::Screen handler: ".$@); };

	return bless $self => $class;
	};


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Term::Screen::Uni - Works exactly as L<Term::Screen> (version 1.09) on evry platform Term::Screen is working plus Win32

I<Version 0.04>

=head1 SYNOPSIS

    use Term::Screen::Uni;
    #
    # Do all the stuff you can do with Term::Screen
    #

See L<Term::Screen> for details

=head1 DESCRIPTION

This module in an interface to L<Term::Screen::Win32> on Win32,
and to L<Term::Screen> on other platforms.

Written just to make one of my scripts platform-independed

=head2 EXPORT

None.



=head1 SEE ALSO

L<Term::Screen>, L<Term::Screen::Win32>


=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
