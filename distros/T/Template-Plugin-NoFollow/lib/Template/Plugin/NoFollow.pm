package Template::Plugin::NoFollow;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use HTML::Parser;
use base qw(Template::Plugin::Filter);

###############################################################################
# Version number.
###############################################################################
our $VERSION = '1.02';

###############################################################################
# Subroutine:   init()
###############################################################################
# Initializes the template plugin.
###############################################################################
sub init {
    my ($self) = @_;
    $self->{'_DYNAMIC'} = 1;
    $self->install_filter( $self->{'_ARGS'}->[0] || 'nofollow' );
    return $self;
}

###############################################################################
# Subroutine:   filter($text, $args, $conf)
###############################################################################
# Filters the given text, and adds rel="nofollow" to links.
###############################################################################
sub filter {
    my ($self, $text, $args, $conf) = @_;

    # Merge the FILTER config with the USE config
    $conf = $self->merge_config( $conf );

    # Get list of "allowed" things (e.g. things we DON'T mark as nofollow)
    my @allow;
    if ($conf->{'allow'}) {
        @allow = ref($conf->{'allow'}) eq 'ARRAY'
                    ? @{$conf->{'allow'}}
                    : $conf->{'allow'};
    }

    # Create a new HTML parser.
    my $filtered = '';
    my $p = HTML::Parser->new(
                'default_h' => [sub { $filtered .= shift; }, 'text'],
                'start_h'   => [sub {
                    my ($tag, $text, $attr) = @_;
                    if ($tag eq 'a') {
                        my $should_nofollow = 1;
                        if (grep { $attr->{'href'} =~ /$_/ } @allow) {
                            $should_nofollow = 0;
                        }
                        if ($should_nofollow) {
                            # remove any existing rel="nofollow" attrs
                            $text =~ s/(<\s*a)([^>]*)\srel\s*=\s*"?nofollow"?([^>]*>)/$1$2$3/gsmi;
                            # add in our rel="nofollow" attr
                            $text =~ s/(<\s*a)([^>]*>)/$1 rel="nofollow"$2/gsmi;
                        }
                    }
                    $filtered .= $text;
                    }, 'tag, text, attr'],
                );

    # Filter the text.
    $p->parse( $text );
    $p->eof();

    # Return the filtered text back to the caller.
    return $filtered;
};

1;

=head1 NAME

Template::Plugin::NoFollow - TT filter to add rel="nofollow" to all HTML links

=head1 SYNOPSIS

  [% use NoFollow allow=['www.example.com', '^http://example.com/'] %]
  ...
  [% FILTER nofollow %]
    <a href="http://www.google.com/">Google</a>
  [% END %]
  ...
  [% text | nofollow %]

=head1 DESCRIPTION

C<Template::Plugin::NoFollow> is a filter plugin for TT, which adds
C<rel="nofollow"> to all HTML links found in the filtered text.

Through the use of the C<allow> option, you can specify URLs that are I<not>
marked as C<rel="nofollow">.  This can be used to set up a filter that leaves
internal links alone, and that marks all external links as C<rel="nofollow">.
C<allow> accepts regular expressions, so you can be as elaborate as you'd like.

=head1 METHODS

=over

=item init()

Initializes the template plugin. 

=item filter($text, $args, $conf)

Filters the given text, and adds rel="nofollow" to links. 

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2006-2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Filter>.

=cut
