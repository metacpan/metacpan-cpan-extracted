package Template::Plugin::Filter::ANSIColor;

use warnings;
use strict;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use Term::Terminfo;
use Term::ANSIColor;


=head1 NAME

Template::Plugin::Filter::ANSIColor - colorizes text using ANSI colors

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This is a Template Toolkit filter that colors the text
using Term::ANSIColor. It works on terminals that support
at least 8 colors.

	use Template;
	
	my $engine = Template->new(
		PLUGIN_BASE => 'Template::Plugin::Filter'
	) || die Template->error();

	$engine->process(\*DATA)
		|| die $engine->error();
		
	__DATA__
	[% USE ANSIColor 'color' %]
	[% "this is red on bright yellow " | color 'red' 'on_bright_yellow' %]
	[% "this is simply green " | color 'green' %]
	[% "this is default on bright magenta" | color 'on_bright_magenta' %]
	[% "this is default on deault since nocolor=1" | color 'red' nocolor = 1 %]		

=head1 METHODS

=head2 init

This method is invoked when Template Toolkit finds a directive [% USE ANSIColor 'color' %].
The argument 'color' is the name for the filter. You may change it if you need.
It has an option 'nocolor', which turns off colors (filter will not modify
the text). Probably you would like to use it the following way:

	# .....
	$engine->process(\*DATA, { colors_off => 1 })
		|| die $engine->error();
	
	__DATA__
	[% USE ANSIColor 'color' nocolor = colors_off %]
	...

See 'TO COLOR OR NOT TO COLOR' below

=cut

sub init {
	my ($self, $terminfo, $nocolor) = @_;
	
	# just for testing!
	if ( ! ref $self ) {
		my $class = $self;
		$self = bless {}, $class;
		$self->{_unit_testing} = 1;
		$self->{_terminfo_instance} = $terminfo;
		$self->{ _CONFIG }->{nocolor} = $nocolor;  
	}
	
	$self->{ _DYNAMIC } = 1;
	$self->install_filter( $self->{_ARGS}[0] || 'color');
	
	if ( !$self->{_terminfo_instance} ) {
		$self->{_terminfo_instance} = Term::Terminfo->new;
	}
	
	return $self;
}

=head2 filter

This is the filter itself. It returns colored text if colors
are not turned off. It accepts one or two parameters, the
foreground and/or background color names. You may also use
nocolor option. See SYNOPSIS above. See TO COLOR OR NOT TO COLOR. 

=cut

sub filter {
	my ($self, $text, $args, $conf) = @_;
	return q{}
		unless $text;
	
	my $colors = $self->{_terminfo_instance}->num_by_varname('max_colors');
	
	$conf =  $self->merge_config($conf);
	
	if ( $conf->{nocolor} || !$colors || $colors < 8 ){
		return $text;
	}
	
	my ($color, $bgcolor);
	$color		= $args->[0] || q{};
	$bgcolor	= $args->[1] || q{};
	
	return colored( [ "$color $bgcolor" ], $text );
}

=begin Developers

=head2 install_filter

This is used by unit tests

=end Developers

=cut

sub install_filter {
	my($self, $name) = @_;
	$self->SUPER::install_filter($name)
		unless $self->{_unit_testing};
}

1;
__END__

=head1 TO COLOR OR NOT TO COLOR

Text is not modified if

=over

=item * nocolor option is on

=item * Term::Terminfo says that the maximum number of colors
supported by current terminal is less than 8 or undefined.

=back

=cut

=head1 SEE ALSO

=over

=item * L<Template>

=item * L<Term::ANSIColor>

=item * L<Term::Terminfo>

=item * L<Template::Plugin::Filter>

=back

=head1 AUTHOR

"Andrei V. Toutoukine", C<< <"tut at isuct.ru"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-filter-ansicolor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Filter-ANSIColor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Filter::ANSIColor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Filter-ANSIColor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-Filter-ANSIColor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-Filter-ANSIColor>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-Filter-ANSIColor/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Andrei V. Toutoukine".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


