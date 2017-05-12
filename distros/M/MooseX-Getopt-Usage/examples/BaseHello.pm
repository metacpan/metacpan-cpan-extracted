package BaseHello;
use 5.010;
use Moose::Role;

around getopt_usage_config => sub {
    my $orig  = shift;
    my $class = shift;
    return (
        attr_sort => sub { $_[0]->name cmp $_[1]->name },
        format => "Usage: %c [OPTIONS]",
        headings => 0,
        $class->$orig(@_),
    );
};

1;
