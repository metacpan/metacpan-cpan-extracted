package Term::Screen::Win32::CursorAndSize;
use 5.005;
use strict;
use warnings;

use Carp;
use Win32::Console::ANSI;

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
	my $key = lc($_[1]);

	if ($key eq 'c')
		{ printf("\e[%d;%dH", (Win32::Console::ANSI::Cursor())[1], $_[2]+1); }
	elsif ($key eq 'r')
		{ printf("\e[%d;%dH", $_[2]+1, (Win32::Console::ANSI::Cursor())[0]); }
	elsif ($key eq 'cols')
		{
		if (!Win32::Console::ANSI::SetConsoleSize($_[2], (Win32::Console::ANSI::XYMax())[1]))
			{ croak 'Could not set console size: '.$^E; };
		}
	elsif ($key eq 'rows')
		{
		if (!Win32::Console::ANSI::SetConsoleSize((Win32::Console::ANSI::XYMax())[0], $_[2]))
			{ croak 'Could not set console size: '.$^E; };
		}
	else
		{ $_[0]{$_[1]} = $_[2]; };
	};

sub FETCH
	{
	my $key = lc($_[1]);

	if ($key eq 'c')
		{ return ((Win32::Console::ANSI::Cursor())[0] - 1); }
	elsif ($key eq 'r')
		{ return ((Win32::Console::ANSI::Cursor())[1] - 1); }
	elsif ($key eq 'cols')
		{ return (Win32::Console::ANSI::XYMax())[0]; }
	elsif ($key eq 'rows')
		{ return (Win32::Console::ANSI::XYMax())[1]; }
	else
		{ return $_[0]{$_[1]}; };
	};


package Term::Screen::Win32;

use 5.005;
use strict;
use warnings;

use Carp;
use Win32::Console::ANSI;
use Win32::Console;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Term::Screen::Win32 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

sub term
	{ croak 'This function is not supported on your platform ('.$^O.')'; };

sub rows
	{ return $_[0]->{'rows'}; };

sub cols
	{ return $_[0]->{'cols'}; };

sub at
	{
	if (defined($_[1])) { $_[0]->{'r'} = $_[1]; };
	if (defined($_[2])) { $_[0]->{'c'} = $_[2]; };
	return $_[0];
	};

sub resize
	{
	if (defined($_[1])) { $_[0]->{'rows'} = $_[1]; };
	if (defined($_[2])) { $_[0]->{'cols'} = $_[2]; };
	
	return ($_[0]->{'rows'}, $_[0]->{'cols'});
	};

sub normal      { print "\e[0m"; return $_[0]; };
sub bold        { print "\e[1m"; return $_[0]; };
sub reverse     { print "\e[7m"; return $_[0]; };
sub clrscr      { print "\e[2J"; return $_[0]; };
sub clreol      { print "\e[0K"; return $_[0]; };
sub clreos      { print "\e[0J"; return $_[0]; };
sub il          { print "\e[".(defined($_[1]) ? $_[1] : 1).'L'; return $_[0]; };
sub dl          { print "\e[".(defined($_[1]) ? $_[1] : 1).'M'; return $_[0]; };
sub ic_exists   { return 1; };
sub ic          { print "\e[".(defined($_[1]) ? $_[1] : 1).'\@'; return $_[0]; };
sub dc_exists   { return 1; };
sub dc          { print "\e[".(defined($_[1]) ? $_[1] : 1).'P'; return $_[0]; };
sub puts        { my $this = shift; print(@_); return $this; };

sub getch
	{
	key_pressed($_[0], 0);
	return shift(@{$_[0]->{'key_pressed'}});
	};

sub def_key
	{ $_[0]->{'def_key'}{$_[1]} = $_[2]; };

sub parseKeyEvent
	{
	if ($_[1]->[5] != 0)
		{ return chr($_[1]->[5]); };

	if (exists($_[0]->{'def_key'}{$_[1]->[3]}))
		{ return $_[0]->{'def_key'}{$_[1]->[3]}; };
	
	return 'noop';
	};

sub fetchKeyEvent
	{
	while($_[0]->{'console'}->GetEvents())
		{
		my @key_pressed = $_[0]->{'console'}->Input();
		if (defined($key_pressed[0]) && ($key_pressed[0] == 1) && $key_pressed[1])
			{ return \@key_pressed; };
		};
	return undef;
	};

sub key_pressed
	{
	if (scalar(@{$_[0]->{'key_pressed'}}))
		{ return 1; };

	my $expTime = time() + (defined($_[1]) ? (($_[1] > 0) ? $_[1] : 999999) : -1);

	while(1)
		{
		my $keyEvent = fetchKeyEvent($_[0]);

		if (defined($keyEvent))
			{
			push(@{$_[0]->{'key_pressed'}}, parseKeyEvent($_[0], $keyEvent));
			return 1;
			};

		if (time() > $expTime)
			{ last; };
		
		sleep(0.02);
		};
	return 0;
	};

sub echo
	{ $_[0]->{'console'}->Mode($_[0]->{'console'}->Mode() | ENABLE_ECHO_INPUT); return $_[0]; };

sub noecho
	{ $_[0]->{'console'}->Mode($_[0]->{'console'}->Mode() & (0xFFFF xor ENABLE_ECHO_INPUT)); return $_[0]; };

sub flush_input
	{ while(key_pressed($_[0])) { getch($_[0]); }; return $_[0]; };

sub stuff_input
	{ push(@{(shift(@_))->{'key_pressed'}}, @_); return $_[0]; };

my %def_key = ( 16 => 'shift',
                17 => 'ctrl',
                18 => 'alt',
                19 => 'pause',
                20 => 'capslock',
                33 => 'pgup',
                34 => 'pgdn',
                35 => 'end',
                36 => 'home',
                37 => 'kl',
                38 => 'ku',
                39 => 'kr',
                40 => 'kd',
                45 => 'ins',
                46 => 'del',
                91 => 'lwin',
                92 => 'rwin',
                93 => 'winmenu',
               112 => 'k1',
               113 => 'k2',
               114 => 'k3',
               115 => 'k4',
               116 => 'k5',
               117 => 'k6',
               118 => 'k7',
               119 => 'k8',
               120 => 'k9',
               121 => 'k10',
               122 => 'k11',
               123 => 'k12',
               145 => 'scrlock',
               144 => 'numlock',
              );
 

sub new($%)
	{
	my ($class) = @_;

	my $self = undef;

	tie(%{$self}, 'Term::Screen::Win32::CursorAndSize');

	$self->{'key_pressed'} = [],
	$self->{'def_key'}     = {},
	$self->{'console'}     = Win32::Console->new(STD_INPUT_HANDLE),

    $self->{'origMode'} = $self->{'console'}->Mode();
    $self->{'console'}->Mode(ENABLE_PROCESSED_INPUT);
    at($self, 0, 0);

    %{$self->{'def_key'}} = %def_key;

	return bless $self => $class;
	};

sub cleanup
	{
	$_[0]->normal();
	if (defined($_[0]->{'console'}))
		{ $_[0]->{'console'}->Mode($_[0]->{'origMode'}); };
	};

sub DESTROY
	{ cleanup(@_); };


 1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Term::Screen::Win32 - Simple L<Term::Screen> style interface to the L<Win32::Console> (and L<Win32::Console::ANSI>) capabilities

I<Version 0.03>

=head1 SYNOPSIS

    use Term::Screen::Win32;
    #
    # Do all the stuff you can do with Term::Screen
    #

See L<Term::Screen> for details

=head1 DESCRIPTION

This module provides the same interface as L<Term::Screen> provides.

It was created to be used with L<Term::Screen::Uni>.

=head2 Functions are not supported

These functions are not supported and will croak if called:

=item C<term()>

Useless on Win32

These functions are different from L<Term::Screen>:

=item C<def_key('name','input string')>

Provide 'virtual keycode' as an 'input string'

These functions are not exists in L<Term::Screen>:

=item C<cleanup()>

Return console to the origuinal mode. Called automatically on C<DESTROY>.

=head2 EXPORT

None.



=head1 SEE ALSO

L<Term::Screen>, L<Win32::Console>, L<Win32::Console::ANSI>


=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
