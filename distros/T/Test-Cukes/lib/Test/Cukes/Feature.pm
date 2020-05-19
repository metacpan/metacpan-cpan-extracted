package Test::Cukes::Feature;
use Moose;

use Test::Cukes::Scenario;

has name => (
    is => "rw",
    required => 1,
    isa => "Str"
);

has body => (
    is => "rw",
    isa => "Str"
);

has scenarios => (
    is => "rw",
    isa => "ArrayRef[Test::Cukes::Scenario]"
);

sub BUILDARGS {
    my $class = shift;
    if (@_ == 1 && ! ref $_[0]) {
        my $text = shift;
        my $args = {
            name => "",
            body => "",
            scenarios => []
        };
        my @blocks = split /\n\n/, $text;
        my $meta = shift @blocks;

        unless ($meta =~ m/^Feature:\s([^\n]+x?)$(.+)\z/sm) {
            die "Cannot extra feature name and body from text:\n----\n$meta\n----\n\n";
        }

        $args->{name} = $1;
        $args->{body} = $2;

        for my $scenario_text (@blocks) {
            unless ($scenario_text =~ s/^  (.+?)$/$1/mg) {
                die "Scenario text is not properly indented:\n----\n${scenario_text}\n----\n\n";
            } 
            push @{$args->{scenarios}}, Test::Cukes::Scenario->new($scenario_text)
        }

        return $args;
    }

    return $class->SUPER::BUILDARGS(@_);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
