package Pcore::WebDriver::WebElement;

use Pcore -class;
use Pcore::WebDriver qw[:WD_LOCATOR];

with qw[Pcore::Util::Result::Status];

has webdriver => ( is => 'ro', isa => ConsumerOf ['Pcore::WebDriver'], required => 1 );
has id => ( is => 'ro', isa => Str, required => 1 );

sub TO_DATA ($self) {
    return $self->{id};
}

# ELEMENT RETRIEVAL - FIND ELEMENT
sub find_element ( $self, $locator, $selector, $cb = undef ) {
    return $self->{webdriver}->_send_command(
        'POST',
        "/session/$self->{webdriver}->{session_id}/element/$self->{id}/element",
        {   using => $locator,
            value => $selector,
        },
        $cb,
        sub ( $res, $cb ) {
            if ($res) {
                $res = bless {
                    webdriver => $self->{webdriver},
                    status    => $res->{status},
                    reason    => $res->{reason},
                    id        => $res->{data}->{ELEMENT},
                  },
                  'Pcore::WebDriver::WebElement';
            }

            $cb->($res);

            return;
        }
    );
}

sub find_element_by_class_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_CLASS_NAME, $selector, $cb );
}

sub find_element_by_css_selector ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_CSS_SELECTOR, $selector, $cb );
}

sub find_element_by_id ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_ID, $selector, $cb );
}

sub find_element_by_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_NAME, $selector, $cb );
}

sub find_element_by_link_text ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_LINK_TEXT, $selector, $cb );
}

sub find_element_by_link_text_part ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_LINK_TEXT_PART, $selector, $cb );
}

sub find_element_by_tag_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_TAG_NAME, $selector, $cb );
}

sub find_element_by_xpath ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_XPATH, $selector, $cb );
}

# ELEMENT RETRIEVAL - FIND ELEMENTS
sub find_elements ( $self, $locator, $selector, $cb = undef ) {
    return $self->{webdriver}->_send_command(
        'POST',
        "/session/$self->{webdriver}->{session_id}/element/$self->{id}/elements",
        {   using => $locator,
            value => $selector,
        },
        $cb,
        sub ( $res, $cb ) {
            if ($res) {
                my $elements = delete $res->{data};

                for my $el ( $elements->@* ) {
                    push $res->{data}->@*,
                      bless {
                        webdriver => $self->{webdriver},
                        status    => $res->{status},
                        reason    => $res->{reason},
                        id        => $el->{ELEMENT},
                      },
                      'Pcore::WebDriver::WebElement';
                }
            }

            $cb->($res);

            return;
        }
    );
}

sub find_elements_by_class_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_CLASS_NAME, $selector, $cb );
}

sub find_elements_by_css_selector ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_CSS_SELECTOR, $selector, $cb );
}

sub find_elements_by_id ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_ID, $selector, $cb );
}

sub find_elements_by_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_NAME, $selector, $cb );
}

sub find_elements_by_link_text ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_LINK_TEXT, $selector, $cb );
}

sub find_elements_by_link_text_part ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_LINK_TEXT_PART, $selector, $cb );
}

sub find_elements_by_tag_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_TAG_NAME, $selector, $cb );
}

sub find_elements_by_xpath ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_XPATH, $selector, $cb );
}

# TODO methods to implement

# is_selected
# set_selected
# toggle
# is_enabled
# get_value
# is_displayed
# is_hidden
# drag
# get_css_attr
# describe

# ELEMENT STATE
sub get_location ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/location", undef, $cb );
}

sub get_location_in_view ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/location_in_view", undef, $cb );
}

sub get_size ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/size", undef, $cb );
}

sub is_selected ( $self, $cb = undef ) {
    ...;

    return;
}

sub get_attr ( $self, $attr, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/attribute/$attr", undef, $cb );
}

sub get_property ( $self, $cb = undef ) {
    ...;

    return;
}

sub get_css_value ( $self, $cb = undef ) {
    ...;

    return;
}

sub get_text ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/text", undef, $cb );
}

sub get_tag_name ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'GET', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/name", undef, $cb );
}

sub get_rect ( $self, $cb = undef ) {
    ...;

    return;
}

sub is_enabled ( $self, $cb = undef ) {
    ...;

    return;
}

# ELEMENT INTERACTION
sub click ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'POST', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/click", undef, $cb );
}

sub clear ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'POST', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/clear", undef, $cb );
}

sub submit ( $self, $cb = undef ) {
    return $self->{webdriver}->_send_command( 'POST', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/submit", undef, $cb );
}

sub send_keys ( $self, $keys, $cb = undef ) {
    $keys = [$keys] if ref $keys ne 'ARRAY';

    map {qq[$_]} $keys->@*;

    return $self->{webdriver}->_send_command( 'POST', "/session/$self->{webdriver}->{session_id}/element/$self->{id}/value", { value => $keys }, $cb );
}

# SCREEN CAPTURE
sub get_screenshot ( $self, $cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    my $done = sub ($res) {
        $cb->($res) if $cb;

        $blocking_cv->($res) if $blocking_cv;

        return;
    };

    my $start = sub {
        $self->get_location(
            sub ($location) {
                if ( !$location ) {
                    $done->($location);
                }
                else {
                    $self->get_size(
                        sub ($size) {
                            if ( !$size ) {
                                $done->($size);
                            }
                            else {
                                $self->{webdriver}->get_screenshot(
                                    {   left   => $location->{data}->{x},
                                        top    => $location->{data}->{y},
                                        width  => $size->{data}->{width},
                                        height => $size->{data}->{height}
                                    },
                                    $done
                                );
                            }

                            return;
                        }
                    );
                }

                return;
            }
        );

        return;
    };

    my $include_flash = 0;

    if ($include_flash) {
        $self->set_wmode(
            sub ($wmode) {
                if ( !$wmode ) {
                    $done->($wmode);
                }
                else {
                    $start->();
                }

                return;
            }
        );
    }
    else {
        $start->();
    }

    return $blocking_cv ? $blocking_cv->recv : undef;
}

sub set_wmode ( $self, $cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    my $done = sub ($res) {
        $cb->($res) if $cb;

        $blocking_cv->($res) if $blocking_cv;

        return;
    };

    $self->get_tag_name(
        sub ($tag_name) {
            if ( !$tag_name ) {
                $done->($tag_name);
            }
            elsif ( $tag_name->{data} eq 'embed' ) {
                my $js = <<'JS';
                    if (!arguments[0].getAttribute('wmode') || arguments[0].getAttribute('wmode').toLowerCase() == 'window'){
                        var embed = arguments[0].cloneNode(true);
                        embed.setAttribute('wmode', 'transparent');
                        arguments[0].parentNode.replaceChild(embed, arguments[0]);
                    }
JS
                $self->{webdriver}->exec( $js, $self, $done );

            }
            else {
                $self->{webdriver}->set_wmode( $self, $done );
            }

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : undef;
}

sub trigger_event ( $self, $ev, $cb = undef ) {
    return $self->{webdriver}->exec( "arguments[0].$ev()", $self, $cb );
}

sub set_attr ( $self, $attr, $val, $cb = undef ) {
    $val =~ s/'/\\'/smg;

    return $self->{webdriver}->exec( "arguments[0].$attr = '$val'", $self, $cb );
}

# sub get_image {
#     my $self = shift;
#     my %args = (
#         method => 'screenshot',    # screenshot | canvas
#         @_
#     );
#
#     unless ( $self->get_tag_name eq 'img' ) {
#         die 'Not an img tag';
#     }
#     else {
#         if ( $args{method} eq 'screenshot' ) {
#             return $self->screenshot;
#         }
#         elsif ( $args{method} eq 'canvas' ) {
#             my $js = <<'JS';
#                 var canvas = document.createElement('canvas');
#                 canvas.width = arguments[0].width;
#                 canvas.height = arguments[0].height;
#                 var ctx = canvas.getContext('2d');
#                 ctx.drawImage(arguments[0], 0, 0);
#                 var imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
#                 return {data: imageData.data, width: canvas.width, height: canvas.height};
# JS
#             my $data = $self->{driver}->execute_script( $js, $self );
#
#             state $init = !!require Imager;
#
#             my $x = 0;
#
#             my $y = 0;
#
#             my $img = Imager->new( xsize => $data->{width}, ysize => $data->{height} );
#
#             for ( my $i = 0; $i <= $#{ $data->{data} }; $i += 4 ) {
#                 $img->setpixel( x => $x, y => $y, color => Imager::Color->new( $data->{data}->[$i], $data->{data}->[ $i + 1 ], $data->{data}->[ $i + 2 ], $data->{data}->[ $i + 3 ] ) );
#                 if ( ++$x == $data->{width} ) {
#                     $x = 0;
#                     $y++;
#                 }
#             }
#             my $image;
#             $img->write( data => \$image, type => 'png' );
#             return { data => \$image, type => 'png', width => $data->{width}, height => $data->{height} };
#         }
#         else {
#             die 'Unknown get_image method';
#         }
#     }
# }

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 165, 175, 181, 195,  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |      | 201                  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::WebElement

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
