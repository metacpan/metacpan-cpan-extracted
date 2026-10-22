package Example::Plan;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(validate_plan);

# Pure policy example: no Rex, network, file reads, or side effects.
# Lexical path constraints do not defend against symlinks or filesystem races.
sub validate_plan {
    my ($input, $root) = @_;
    die "Plan must be a hash reference\n" unless ref($input) eq 'HASH';
    die "Approved root must be a non-root absolute lexical directory\n"
        unless defined($root) && !ref($root) && $root =~ m{\A/[A-Za-z0-9._/-]+\z}
        && $root ne '/' && $root !~ m{(?:\A|/)\.\.?(?:/|\z)} && $root !~ m{//};
    $root =~ s{/$}{};
    my %allowed = map { $_ => 1 } qw(name path content);
    die "Unknown plan field\n" if grep { !$allowed{$_} } keys %$input;
    for my $field (qw(name path content)) {
        die "Missing or non-scalar plan field: $field\n"
            unless exists($input->{$field}) && defined($input->{$field}) && !ref($input->{$field});
    }
    die "Invalid application name\n" unless $input->{name} =~ /\A[a-z][a-z0-9_-]{0,62}\z/;
    my $path = $input->{path};
    die "Invalid path\n" unless $path =~ m{\A/[A-Za-z0-9._/-]+\z}
        && $path !~ m{(?:\A|/)\.\.?(?:/|\z)} && $path !~ m{//}
        && $path !~ m{/$} && index($path, "$root/") == 0;
    die "Content exceeds example limit\n" if length($input->{content}) > 65536;
    return {name => $input->{name}, path => $path, content => $input->{content}};
}
1;
