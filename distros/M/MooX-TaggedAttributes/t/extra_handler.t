#!perl

use Sub::Identify 'sub_fullname';
use Test2::V0;
use Test::Lib;
use My::Test;


use aliased 'My::Handler::C1';
use aliased 'My::Handler::C2';
use aliased 'My::Handler::C12';
use aliased 'My::Handler::C1_2';
use aliased 'My::Handler::CC1';
use aliased 'My::Handler::CC1_2';

# ensure that the tag handlers are properly appended for
#  * classes which consume multiple roles, e.g.  with 'T1', 'T2';
#  * classes which consume a role which consumes multiple roles, e.g. with 'T12'.

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
        field 'My::Handler::C1' => array {
            item "My::Handler::T1::make_tag_handler";
            end;
        };
        field 'My::Handler::C1_2' => array {
            item "My::Handler::T1::make_tag_handler";
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::C2' => array {
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::C12' => array {
            item "My::Handler::T1::make_tag_handler";
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::CC1' => array {
            item "My::Handler::T1::make_tag_handler";
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::CC1_2' => array {
            item "My::Handler::T1::make_tag_handler";
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::T1' => array {
            item "My::Handler::T1::make_tag_handler";
            end;
        };
        field 'My::Handler::T2' => array {
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        field 'My::Handler::T12' => array {
            item "My::Handler::T1::make_tag_handler";
            item "My::Handler::T2::make_tag_handler";
            end;
        };
        end;
    },
    'tag handlers'
);

is(
    C1->new->_tags->tag_hash,
    hash {
        field T1 => hash {
            field c1 => array {
                item array {
                    item "My::Handler::T1";
                    item "My::Handler::C1";
                    end;
                };
                end;
            };
            end;
        };
        end;
    },
    'C1 tags'
);

is(
    C2->new->_tags->tag_hash,
    hash {
        field T2 => hash {
            field c2 => array {
                item array {
                    item "My::Handler::T2";
                    item "My::Handler::C2";
                    end;
                };
                end;
            };
            end;
        };
        end;
    },
    'C2 tags',
);

is(
    C12->new->_tags->tag_hash,
    hash {
        field T2 => hash {
            field 'c12' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::C12';
                    end;
                };
                end;
            };
            field 't1t2' => [ [ 'My::Handler::T2', 'My::Handler::T12' ] ];
            end;
        };

        field 'T1' => hash {
            field 'c12' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::C12';
                    end;
                };
                end;
            };
            field 't1t2' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::T12';
                    end;
                };
            };
            end;
        };
    },
    'C12 tags'
);

is(
    C1_2->new->_tags->tag_hash,
    hash {
        field 'T2' => hash {
            field 'c1_2' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::C1_2';
                    end;
                };
                end;
            };
            end;
        };
        field 'T1' => hash {
            field 'c1_2' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::C1_2';
                    end;
                };
                end;
            };
            end;
        };
        end;
    },
    'C1_2 tags'
);

is(
    CC1->new->_tags->tag_hash,
    hash {
        field 'T2' => hash {
            field 't1t2' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::T12';
                    end;
                };
                end;
            };
            field 'cc1' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::CC1';
                    end;
                };
                end;
            };
            end;
        };
        field 'T1' => hash {
            field 'cc1' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::CC1';
                    end;
                };
                end;
            };
            field 't1t2' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::T12';
                    end;
                };
                end;
            };
            field 'c1' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::C1';
                    end;
                };
                end;
            };
            end;
        };
        end;
    },
    'CC1 tags',
);


is(
    CC1_2->new->_tags->tag_hash,
    hash {
        field 'T2' => hash {
            field 't1t2' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::T12';
                    end;
                };
                end;
            };
            field 'c2' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::C2';
                    end;
                };
                end;
            };
            field 'cc1_2' => array {
                item array {
                    item 'My::Handler::T2';
                    item 'My::Handler::CC1_2';
                    end;
                };
                end;
            };
            end;
        };
        field 'T1' => hash {
            field 'cc1_2' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::CC1_2';
                    end;
                };
                end;
            };
            field 't1t2' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::T12';
                    end;
                };
                end;
            };
            field 'c1' => array {
                item array {
                    item 'My::Handler::T1';
                    item 'My::Handler::C1';
                    end;
                };
                end;
            };
            end;
        };
        end;
    },
    'CC1_2 tags'
);

done_testing;
