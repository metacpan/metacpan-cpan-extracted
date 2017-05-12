package ToggleTester;


use Modern::Perl;
use Test::Routine;
use Test::More;
use Test::Deep ();
use Test::Exception;
use namespace::autoclean;
has domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => 'get_domains_to_test'
);

test can_load_parser => { desc => 'Make sure we can load class' } => sub {
    use_ok( 'ParseUtil::Domain', qw/:simple/ )
      or BAIL_OUT("Can't load parser.");
};

test puny_toggle => { desc => 'Toggle unicode <-> ascii domains' } => sub {
    my ($self) = @_;

    my $domains_to_test = $self->domains_to_test();
    foreach my $domain ( @{$domains_to_test} ) {
        say $domain;
        lives_ok {
            puny_convert($domain);
        }
        'No problems parsing domain';
    }
};

"one, but we're not the same";


__END__

=head1 NAME

ToggleTester - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...


