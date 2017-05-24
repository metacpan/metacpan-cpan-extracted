package Template::Plugin::WikiFormat;
use strict;
use warnings;

our $VERSION = '0.08';

#----------------------------------------------------------------------------

=head1 NAME

Template::Plugin::WikiFormat - TT wrapper for Text::WikiFormat

=head1 SYNOPSIS

  [% USE WikiFormat %]
  [% FILTER $WikiFormat %]
  ...
  [% END %]

=head1 DESCRIPTION

This is a plugin used for wiki rendering inside Template Toolkit.

Parameters may be passed in through the USE directive, e.g. 

  [% USE WikiFormat prefix = "http://www.mysite.com/?page=" %]

This provides the 4 options supported by L<Text::WikiFormat>, i.e.
C<prefix, extended, implicit_links, absolute_links>, and the special option 
global_replace, which takes an array of arrays of from and to strings. The 
output from Text::WikiFormat is post processed by replacing each from regexp 
with the to regexp. Anything else passed in is interpreted as a tag (see the 
Gory Details section).

=head2 filter

Accepts the wiki text to be rendered, and context. The tags and options are
passed in through the context. See L<Template::Plugin::Filter>.

=cut

#----------------------------------------------------------------------------

#############################################################################
#Library Modules															#
#############################################################################

use base 'Template::Plugin::Filter';
use Text::WikiFormat;

#----------------------------------------------------------------------------

#############################################################################
#Interface Methods   														#
#############################################################################

sub filter {
    my ( $self, $text ) = @_;

    my $conf = $self->{_CONFIG};
    $conf ||= {};
    my %tags = %$conf;
    my %opts;
    my %default = (
        prefix         => '',
        extended       => 0,
        implicit_links => 1,
        absolute_links => 0,
    );
    for ( keys %default ) {
        $opts{$_} = $tags{$_} || $default{$_};
        delete $tags{$_};
    }
    my $replace;
    if ( exists $tags{global_replace} ) {
        $replace = $tags{global_replace};
        delete $tags{global_replace};
    }

    my $output = Text::WikiFormat::format( $text, \%tags, \%opts );

    for my $rep (@$replace) {
        my ( $from, $to ) = @$rep;
        eval("\$output =~ s($from)($to)sg");
    }
    return $output;
}

1;

__END__

#----------------------------------------------------------------------------

=head1 SEE ALSO

L<Text::WikiFormat>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (see link below). However, it would help greatly if you are able to 
pinpoint problems or even supply a patch.

http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-WikiFormat

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Original Author: Ivor Williams (RIP)          2008-2009
  Current Maintainer: Barbie <barbie@cpan.org>  2009-2017

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2009 Ivor Williams
  Copyright (C) 2009-2017 Barbie

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

