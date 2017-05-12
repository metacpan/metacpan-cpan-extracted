# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter;

use strict;
use vars qw($VERSION);

$VERSION = 'v1.17';

# This package works like an interface description to the Show.pm
# package, which runs the show.  The interface is defined to restrict
# users of PPresenter from routines which may change in the future.
#
# Read the documentation (in HTML) for details on usage.

use PPresenter::Show;

sub copyright()
{   <<COPYLEFT
Portable Presenter $VERSION (2002/08/12), Mark Overmeer.
Copyright (C) 2000-2002, Free Software Foundation FSF.
PPresenter is available under GPL, and comes with absolutely NO WARRANTY.  
Please read the copyright message.

COPYLEFT
}

#: use PPresenter
#: my $show = PPresenter->new(@args);     # args from %Show::ObjDefaults

sub new($@)
{   my $class = shift;

    print copyright;

    my $show = PPresenter::Show->new(@_);

    bless \$show, $class;                 # ref to Show to hide methods of Show.
}

sub run()           {${(shift)}->run }

#: Tk has a definition for object "Screen", so we call it "Viewport".  The
#: user is not bothered with the object's name, so can also use the name
#: "screen" in the function calls.

#: my $screen = $show->addViewport(@args);
#: $show->addViewports(screens);
#:     addScreen  equivalent to addViewport
#:     addScreens equivalent to addViewports

sub addViewport(@)  {${(shift)}->add('viewport', @_) }
sub addViewports(@) {shift->addViewport(@_)}
sub addScreen(@)    {shift->addViewport(@_)}
sub addScreens(@)   {shift->addViewport(@_)}

#: my $style  = $show->addStyle(style-object-name)
#: my @styles = $show->addStyle(style-object-names);
#: my @styles = $show->addStyle([style-object-names]);

sub addStyle(@)  {${(shift)}->add('style', @_) }

#: my $slide  = $show->addSlide(slide-data);
#: my $slide  = $show->addSlide(slide);
#: my @slides = $show->addSlides(slide,slide,...);

sub addSlide(@)  {${(shift)}->add('slide', @_) }
sub addSlides(@) {shift->addSlide(@_)}

#: my $elem   = $show->find(elem-type, name);
#:   name may be 'SELECTED' (the one selected, default),
#:               'FIRST', 'LAST', number (sequence number),
#:               or from -name/-aliases
#: my @elems  = $show->find(elem-type, 'ALL');
#: There is also a $viewport->find and a $style->find.

sub find(@)   {${(shift)}->find(@_) }

#: my $viewport = $show->select(viewport => name);
#: my    @elems = $show->select(style or style-elem => name);
#: There is also a $viewport->select and a $style->select.

sub select(@) {${(shift)}->select(@_) }

#: my $object  = $show->change(style-elem => name, options);  #sel-style
#: my @objects = $show->change(style-elem => 'ALL', options);
#: my $object  = $show->find(style => name)->change(style-elem=>name, options);

sub change(@) {${(shift)}->changeDefaults(@_) }

#: my $img     = $show->image(options);

sub image(@)       {${(shift)}->image(@_) }
sub addImageDir(@) {${(shift)}->addImageDir(@_) }
sub Photo(@)       {${(shift)}->Photo(@_) }

#: my $exporter = $show->addExporter(module-name, options);
#: my $exporter = $show->addExporter(exporter-object, options);

sub addExporter(@) {${(shift)}->addExporter(@_) }

# Portability fix for Windows
$ENV{TMPDIR} ||= $ENV{TEMP} || ($^O =~ /^Win/ ? 'C:/temp' : '/var/tmp');

1;
__END__

=head1 NAME

PPresenter - Slide shows written in Perl (or XML)

=head1 SYNOPSIS

=head1 DESCRIPTION

I<Portable Presenter> (PPresenter) is a package designed to give presentations.
It is written in pure Perl/Tk, which is available for UNIX and for Windows.

=head1 SEE ALSO

The documentation for PPresenter can be found at its web-site:
L<http://ppresenter.org>.

=head1 AUTHOR

Mark Overmeer (F<mailbox@overmeer.net>).

Copyright (c) 2001-2002 Mark Overmeer. All rights reserved.
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

cut

