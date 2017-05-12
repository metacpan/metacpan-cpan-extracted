package Template::Plugin::Filter::HTMLScrubber;

use strict;
use warnings;

our $VERSION = '0.03';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use Carp;
use HTML::Scrubber;

sub init {
    my ( $self, @args ) = @_;

    my $config = ( ref $args[-1] eq 'HASH' ) ? pop @args : {};
    my $_scrubber_map = {};

    unless ( defined $config->{base} ) {

        # do default setting
        $_scrubber_map = {
            base => {
                allow => [qw| br hr b a u del i |],
                rules => [
                    script => 0,
                    span   => {
                        style => qr{^(?!(?:java)?script)}i,
                        class => qr{^(?!(?:java)?script)}i,
                        '*'   => 0,
                    },
                    img => {
                        src   => qr{^(?!(?:java)?script)}i,
                        alt   => qr{^(?!(?:java)?script)}i,
                        title => qr{^(?!(?:java)?script)}i,
                        class => qr{^(?!(?:java)?script)}i,
                        '*'   => 0,
                    },
                ],
                default => [
                    0 => {
                        '*'    => 1,
                        'href' => qr{^(?!(?:java)?script)}i,
                        'src'  => qr{^(?!(?:java)?script)}i,
						'cite' => '(?i-xsm:^(?!(?:java)?script))',
						'language' => 1,
						'name' => 1,
						'onblur' => 0,
						'onchange' => 0,
						'onclick' => 0,
						'ondblclick' => 0,
						'onerror' => 0,
						'onfocus' => 0,
						'onkeydown' => 0,
						'onkeypress' => 0,
						'onkeyup' => 0,
						'onload' => 0,
						'onmousedown' => 0,
						'onmousemove' => 0,
						'onmouseout' => 0,
						'onmouseover' => 0,
						'onmouseup' => 0,
						'onreset' => 0,
						'onselect' => 0,
						'onsubmit' => 0,
						'onunload' => 0,
						'src' => 0,
						'type' => 0,
                    }
                ],
                comment => 1,
                process => 0,
            }
        };
    }
    else {
        foreach my $type ( keys %$config ) {
            $_scrubber_map->{$type} = $config->{$type};
        }
    }

    $_scrubber_map->{$_} = HTML::Scrubber->new( %{ $_scrubber_map->{$_} } )
      foreach ( keys %$_scrubber_map );

    $self->{_DYNAMIC}      = 1;
    $self->{_SCRUBBER_MAP} = $_scrubber_map;

    $self->install_filter('html_scrubber');

    return $self;
}

sub filter {
    my ( $self, $text, $params ) = @_;

    my $level;
    my $attr = [];

    if ( $params->[1] and ( ref $params->[1] eq 'ARRAY' ) ) {
        $attr  = $params->[1];
        $level = $params->[0];
    }
    elsif ( $params->[0] and ( ref $params->[0] eq 'ARRAY' ) ) {
        $attr  = $params->[0];
        $level = 'base';
    }
    elsif ( $params->[0] ) {
        $level = $params->[0];
    }
    else {
        $level = 'base';
    }

    my @allow_tags = ();
    my @deny_tags  = ();

    foreach (@$attr) {
        if    ( $_ =~ m/^\+([0-9a-zA-Z]+)/ ) { push @allow_tags, $1 }
        elsif ( $_ =~ m/^\-([0-9a-zA-Z]+)/ ) { push @deny_tags,  $1 }
    }

    my $scrubber = $self->{_SCRUBBER_MAP}->{$level};
    $scrubber->allow(@allow_tags);
    $scrubber->deny(@deny_tags);

    my $result = $scrubber->scrub($text);

    return $result;
}

1;

__END__

=head1 NAME

Template::Plugin::Filter::HTMLScrubber - Filter Plugin for using HTML::Scrubber in Template , and some additional function;

=head1 VERSION

0.03

=head1 SYNOPSIS

	[% USE Filter.HTMLScrubber %]
	[% html_text | html_scrubber %]
	[% html_text | html_scrubber(['-img']) %]

=head1 DESCRIPTION

This plugin provides an HTML::Scrubber::scrub method to Template Toolkit Filter , 
and enables to specify the scrub level and tags at every parts.

The default usage.

	my $html_text = q[
	<img src="http://your.favorite.photo.jpg" />
	<hr>
	<script>alert('NyanPome!')</script>
	];

	[% USE Filter.HTMLScrubber %]
	[% html_text | html_scrubber %]

Another function of this plugin module enable you to specify allow/deny tags at every part.

	#deny 'img' tag from default scrub level.
	[% html_text_deny_image | html_scrubber(['-img']) %]

	#allow 'script' and 'style' tags to default scrub level.
	[% html_text_loose | html_scrubber(['+script' , '+style']) %]

You can setup the scrubbed tags, then should set "base" config.

	my $setup = {
		base => {
			allow => [qw| br hr b a u del i |],
			rules => [
				script => 0,
				span => {
					style => qr{^(?!(?:java)?script)}i,
					class => qr{^(?!(?:java)?script)}i,
					'*' => 0,
				},
				img => {
					src => qr{^(?!(?:java)?script)}i,
					alt => qr{^(?!(?:java)?script)}i,
					title => qr{^(?!(?:java)?script)}i,
					class => qr{^(?!(?:java)?script)}i,
					'*' => 0,
				},
			],
			default => [
				0 => {
					'*' => 1,
					'href' => qr{^(?!(?:java)?script)}i,
					'src' => qr{^(?!(?:java)?script)}i,
				}
			],
		}
	};

	[% USE Filter.HTMLScrubber setup  %]
	[% html_text | html_scrubber %]

Furthermore, you can specify various level of scrubbing.
When you call html_scrubber,you code the level.

	my $setup = {
		base => .....,
		strict => .....
		loose => .....
	};

	[% USE Filter.HTMLScrubber setup  %]
	[% html_text1 | html_scrubber('strict') %]
	[% html_text2 | html_scrubber('loose',['-img']) %]

=head1 METHODS

=head2 init

Overrided method.
See more detail L<Template::Plugin::Filter>

=head2 filter

Overrided method.
See more detail L<Template::Plugin::Filter>

=head1 CONFIGURATION AND ENVIRONMENT

Template::Plugin::Filter::HTMLScrubber requires no configuration files or environment variables.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-template-plugin-filter-htmlscrubber@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<HTML::Scrubber>, L<HTML::Plugin::Filter>

=cut

=head1 AUTHOR

Yu Isobe  C<< <yupug at cpan.org> >>

=head1 THANKS

Toru Yamaguchi

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yu Isobe C<< <yupug at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


