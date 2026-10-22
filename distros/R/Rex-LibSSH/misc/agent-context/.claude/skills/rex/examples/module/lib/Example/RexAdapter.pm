package Example::RexAdapter;
use strict;
use warnings;
use Rex::Commands::File;
use Example::Plan qw(validate_plan);
use base 'Rex::Exporter';
our @EXPORT = qw(apply_example_config);

sub apply_example_config {
    my ($input, $approved_root) = @_;
    my $plan = validate_plan($input, $approved_root);
    die "Remote-only adapter\n" if Rex::is_local();
    # Caller must authorize the root and ensure trusted ownership/no symlink races.
    # File syntax validation and application activation belong to a domain adapter.
    my $changed = 0;
    file $plan->{path}, content => $plan->{content}, mode => 600,
        on_change => sub { $changed = 1; };
    return {name => $plan->{name}, changed => $changed};
}
1;
