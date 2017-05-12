package t::TestPages;
BEGIN {
    eval qq{
        use base qw(Sledge::TestPages);
        use YAML;
    };
    die $@ if $@;
}

__PACKAGE__->__triggerpoints(
    {
        %{ __PACKAGE__->__triggerpoints },
        BEFORE_OUTPUT => 1,
    }
);

use Sledge::Plugin::Stash;

__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ($self, ) = @_;
        $self->invoke_hook('BEFORE_OUTPUT');
        $self->r->print(
            YAML::Dump(
                {   stash => $self->stash,
                    tmpl  => {
                        map { $_ => $self->tmpl->param($_) }
                            grep !/^(session|r|config)/,
                        $self->tmpl->param
                    }
                }
            )
        );
        $self->finished(1);
    }
);

my $x;
$x = $t::TestPages::TMPL_PATH = 't/';
$x = $t::TestPages::COOKIE_NAME = 'sid';
$ENV{HTTP_COOKIE}    = "sid=SIDSIDSIDSID";
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'foo=bar';

