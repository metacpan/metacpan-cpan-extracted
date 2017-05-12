package Template::Plugin::LinkTarget;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use HTML::Parser;
use HTML::Entities qw(encode_entities);
use base qw(Template::Plugin::Filter);

###############################################################################
# Version number.
###############################################################################
our $VERSION = '0.02';

###############################################################################
# Subroutine:   init()
###############################################################################
# Initializes the template plugin.
###############################################################################
sub init {
    my $self = shift;
    $self->{'_DYNAMIC'} = 1;
    $self->install_filter( $self->{'_ARGS'}->[0] || 'linktarget' );
    return $self;
}

###############################################################################
# Subroutine:   filter($text, $args, $conf)
###############################################################################
# Filters the given text, and adds the "target" attribute to links.
###############################################################################
sub filter {
    my ($self, $text, $args, $conf) = @_;

    # Merge the FILTER config with the USE config
    $conf = $self->merge_config( $conf );

    # Get list of "excluded" things (e.g. things we DON'T add targets to)
    my @exclude;
    if ($conf->{'exclude'}) {
        @exclude = ref($conf->{'exclude'}) eq 'ARRAY'
                    ? @{$conf->{'exclude'}}
                    : $conf->{'exclude'};
    }

    # Get the "target" for links.
    my $target = $conf->{'target'} || '_blank';

    # Create a new HTML parser.
    my $filtered = '';
    my $p = HTML::Parser->new(
        'default_h' => [sub { $filtered .= shift; }, 'text'],
        'start_h'   => [sub {
            my ($tag, $text, $attr, $attrseq) = @_;
            if ($tag eq 'a') {
                my $should_add = 1;
                if (grep { $attr->{'href'} =~ /$_/ } @exclude) {
                    $should_add = 0;
                }
                if ($should_add) {
                    # add in our "target" attr, replacing any existing one
                    unless (exists $attr->{'target'}) {
                        push( @{$attrseq}, 'target' )
                    }
                    $attr->{'target'} = $target;
                    # rebuild the tag
                    my @attrs = map { qq{$_="} . encode_entities($attr->{$_}) . qq{"} }
                                    @{$attrseq};
                    $text = '<a ' . join(' ',@attrs) . '>';
                }
            }
            $filtered .= $text;
            }, 'tag, text, attr, attrseq'],
        );

    # Filter the text.
    $p->parse( $text );
    $p->eof();

    # Return the filtered text back to the caller.
    return $filtered;
}

1;

=head1 NAME

Template::Plugin::LinkTarget - TT filter to add "target" attribute to all HTML links

=head1 SYNOPSIS

  [% USE LinkTarget(target="_blank" exclude=['www.example.com']) %]
  ...
  [% FILTER linktarget %]
    <a href="http://www.google.com/">Google</a>
  [% END %]
  ...
  [% text | linktarget %]

=head1 DESCRIPTION

C<Template::Plugin::LinkTarget> is a filter plugin for TT, which adds a
C<target> attribute to all HTML links found in the filtered text.

Through the use of the C<exclude> option, you can specify URLs that are I<not>
given a new C<target> attribute.  This can be used to set up a filter that
leaves internal links alone but that sets up external links to open in a new
browser window.  C<exclude> accepts a list of regular expressions, so you can
be as elaborate as you'd like.

The C<target> option specifies what target you'd like to give to links,
defaulting to "_blank".

=head1 METHODS

=over

=item init()

Initializes the template plugin. 

=item filter($text, $args, $conf)

Filters the given text, and adds the "target" attribute to links. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2008, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Filter>.

=cut
