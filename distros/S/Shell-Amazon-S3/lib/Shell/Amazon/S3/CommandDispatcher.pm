package Shell::Amazon::S3::CommandDispatcher;
use Moose;
use Module::Pluggable::Object;
use Class::MOP;
use Shell::Amazon::S3::Utils;

has 'dispatch_table' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub {
        my $finder = Module::Pluggable::Object->new(
            search_path => 'Shell::Amazon::S3::Command', );
        my @commands = $finder->plugins;
        Class::MOP::load_class($_) for @commands;
        my %table
            = map { Shell::Amazon::S3::Utils->classsuffix($_) => $_->new }
            @commands;
        \%table;
    }
);

sub dispatch {
    my ( $self, $command, $args ) = @_;
    my $result;
    if ( exists $self->dispatch_table->{$command} ) {
        $result = $self->dispatch_table->{$command}->do_execute($args);
    }
    else {
        $result = 'Unknown command:' . $command;
    }
    $result;
}

__PACKAGE__->meta->make_immutable;

1;
