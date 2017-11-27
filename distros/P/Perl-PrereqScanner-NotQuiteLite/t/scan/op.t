use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # MSERGEANT/XML-QL-0.07/QL.pm
    if ( ( ! $cm->{done} ) && ( $expat->context < $cm->{fail} ) ) {
      $cm->{done} = 1;
      $cm->{reason} = "out of context on $element";
    }
TEST

test(<<'TEST'); # INGY/Spoon-0.24/lib/Spoon/Command.pm
sub process {
    no warnings 'once';
    local *boolean_arguments = sub { qw( -q -quiet ) };
    my ($args, @values) = $self->parse_arguments(@_);
    $self->quiet(1)
      if $args->{-q} || $args->{-quiet};
    my $action = $self->get_action(shift(@values)) ||
                 sub { $self->default_action(@_) };
    $action->(@values);
    return $self;
}
TEST

done_testing;
