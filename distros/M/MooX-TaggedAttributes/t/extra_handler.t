#!perl

use Sub::Identify 'sub_fullname';
use Test2::V0;
use Test::Lib;
use My::Test;
use Package::Stash;

my $pkg = Package::Stash->new( 'main' );

subtest( $_, \&test_it, $_ ) for
  'My::Class::Handler',
  'My::Role::Handler',
  ;


# ensure that the tag handlers are properly appended for
#  * classes which consume multiple roles, e.g.  with 'T1', 'T2';
#  * classes which consume a role which consumes multiple roles, e.g. with 'T12'.


sub test_it {

    my $type = shift;

    my @classes = qw(
      C1
      C2
      C12
      C1_2
      CC1
      CC1_2
    );

    %MooX::TaggedAttributes::TAGHANDLER = ();

    for my $base ( @classes ) {
        my ( $class ) = load( $base, $type );
        no strict 'refs';
        no warnings 'redefine';

        # can't remember how to do this on Perl 5.10.
        # my $glob = *${ \$base };
        # *{$glob} = sub { $class };
        my $sym = '&' . $base;
        $pkg->remove_symbol( $sym );
        $pkg->add_symbol( $sym, sub { $class } );

    }

    my %tag_handlers = (
        map {
            $_ => [
                map sub_fullname( $_ ),
                @{ $MooX::TaggedAttributes::TAGHANDLER{$_} } ]
          }
          keys %MooX::TaggedAttributes::TAGHANDLER
    );

    is(
        \%tag_handlers,
        hash {
            field "${type}::C1" => array {
                item "${type}::T1::make_tag_handler";
                end;
            };
            field "${type}::C1_2" => array {
                item "${type}::T1::make_tag_handler";
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::C2" => array {
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::C12" => array {
                item "${type}::T1::make_tag_handler";
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::CC1" => array {
                item "${type}::T1::make_tag_handler";
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::CC1_2" => array {
                item "${type}::T1::make_tag_handler";
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::T1" => array {
                item "${type}::T1::make_tag_handler";
                end;
            };
            field "${type}::T2" => array {
                item "${type}::T2::make_tag_handler";
                end;
            };
            field "${type}::T12" => array {
                item "${type}::T1::make_tag_handler";
                item "${type}::T2::make_tag_handler";
                end;
            };
            end;
        },
        "tag handlers"
    );


    is(
        C1()->new->_tags->tag_hash,
        hash {
            field T1 => hash {
                field c1 => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::C1";
                        end;
                    };
                    end;
                };
                end;
            };
            end;
        },
        "C1 tags"
    );


    is(
        C2()->new->_tags->tag_hash,
        hash {
            field T2 => hash {
                field c2 => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::C2";
                        end;
                    };
                    end;
                };
                end;
            };
            end;
        },
        "C2 tags",
    );

    is(
        C12()->new->_tags->tag_hash,
        hash {
            field T2 => hash {
                field "c12" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::C12";
                        end;
                    };
                    end;
                };
                field "t1t2" => [ [ "${type}::T2", "${type}::T12" ] ];
                end;
            };

            field "T1" => hash {
                field "c12" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::C12";
                        end;
                    };
                    end;
                };
                field "t1t2" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::T12";
                        end;
                    };
                };
                end;
            };
        },
        "C12 tags"
    );

    is(
        C1_2()->new->_tags->tag_hash,
        hash {
            field "T2" => hash {
                field "c1_2" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::C1_2";
                        end;
                    };
                    end;
                };
                end;
            };
            field "T1" => hash {
                field "c1_2" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::C1_2";
                        end;
                    };
                    end;
                };
                end;
            };
            end;
        },
        "C1_2 tags"
    );

    is(
        CC1()->new->_tags->tag_hash,
        hash {
            field "T2" => hash {
                field "t1t2" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::T12";
                        end;
                    };
                    end;
                };
                field "cc1" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::CC1";
                        end;
                    };
                    end;
                };
                end;
            };
            field "T1" => hash {
                field "cc1" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::CC1";
                        end;
                    };
                    end;
                };
                field "t1t2" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::T12";
                        end;
                    };
                    end;
                };
                field "c1" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::C1";
                        end;
                    };
                    end;
                };
                end;
            };
            end;
        },
        "CC1 tags",
    );


    is(
        CC1_2()->new->_tags->tag_hash,
        hash {
            field "T2" => hash {
                field "t1t2" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::T12";
                        end;
                    };
                    end;
                };
                field "c2" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::C2";
                        end;
                    };
                    end;
                };
                field "cc1_2" => array {
                    item array {
                        item "${type}::T2";
                        item "${type}::CC1_2";
                        end;
                    };
                    end;
                };
                end;
            };
            field "T1" => hash {
                field "cc1_2" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::CC1_2";
                        end;
                    };
                    end;
                };
                field "t1t2" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::T12";
                        end;
                    };
                    end;
                };
                field "c1" => array {
                    item array {
                        item "${type}::T1";
                        item "${type}::C1";
                        end;
                    };
                    end;
                };
                end;
            };
            end;
        },
        "CC1_2 tags"
    );

}

done_testing;
