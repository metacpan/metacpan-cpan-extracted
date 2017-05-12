# ============================================================================
package MooseX::App::Plugin::Man::Command;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
use MooseX::App::Command;
use Pod::Perldoc;

command_short_description q(Full manpage);

has 'command' => (
    is              => 'ro',
    isa             => 'ArrayRef',
    predicate       => 'has_command',
    documentation   => q[Command],
    traits          => ['MooseX::App::Meta::Role::Attribute::Option'],
    cmd_type        => 'parameter',
    cmd_position    => 1,
);

sub man {
    my ($self,$app) = @_;

    my $meta = $app->meta;
    my $class;

    if ($self->has_command) {
        my $return = $meta->command_find($self->command);
        # Nothing found
        if (blessed $return
            && $return->isa('MooseX::App::Message::Block')) {
            return MooseX::App::Message::Envelope->new(
                $return,
                $meta->command_usage_command($self->meta),
            );
        }
        $class = $meta->command_get($return);
    } else {
        $class = $meta->name;
    }

    Class::Load::load_class($class);
    my $filename = MooseX::App::Utils::package_to_filename($class);

    exec('perldoc',$filename);
    #return $MooseX::App::Null::NULL;
}

__PACKAGE__->meta->make_immutable;
1;