# t/new.t
use 5.14.0;
use warnings;
use Test::More tests => 22;

BEGIN { use_ok( 'Perl::RT2Github' ); }

my $self = Perl::RT2Github->new();
isa_ok ($self, 'Perl::RT2Github');

{
    my $self = Perl::RT2Github->new();
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = '123abc';
    local $@;
    eval { $self->get_github_url($rt_id); };
    like($@, qr/RT IDs were numeric/,
        "Got expected exception: non-numeric RT ID");
}

{
    my $self = Perl::RT2Github->new();
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = 125740;
    my $expected = $self->{gh_stem} . 14836;
    my $got = $self->get_github_url($rt_id);
    is($got, $expected, "Got expected github URL");
}

{
    note("Non-existent rt.perl.org ID number");
    my $self = Perl::RT2Github->new();
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = 200895;
    my $expected = undef;
    my $got = $self->get_github_url($rt_id);
    is($got, $expected, "Got undef for non-existent github URL");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my $expected = {
        125740 => "https://github.com/perl/perl5/issues/14836",
        133776 => "https://github.com/perl/perl5/issues/16815",
    };
    my $got = $self->get_github_urls( 125740, 133776 );
    is_deeply($got, $expected, "Got expected github URLs");
}

{
    isa_ok ($self, 'Perl::RT2Github');
    my $self = Perl::RT2Github->new( );
    my $expected = {
        125740 => "https://github.com/perl/perl5/issues/14836",
        200895 => undef,
    };
    my $got = $self->get_github_urls( 125740, 200895 );
    is_deeply($got, $expected, "Got one expected github URL and one not found");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = '123abc';
    local $@;
    eval { $self->get_github_ids( $rt_id ); };
    like($@, qr/RT IDs were numeric/,
        "Got expected exception: non-numeric RT ID");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = 125740;
    my $expected = 14836;
    my $got = $self->get_github_id( $rt_id );
    is($got, $expected, "Got expected github ID for RT $rt_id");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my $rt_id = 200895;
    my $expected = undef;
    my $got = $self->get_github_id( $rt_id );
    is($got, $expected, "Got expected undefined value for nonexistent RT $rt_id");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my @rt_ids = ( 125740, 133776 );
    my $expected = {
        125740 => 14836,
        133776 => 16815,
    };
    my $got = $self->get_github_ids( @rt_ids );
    is_deeply($got, $expected, "Got expected github ID for RT");
}

{
    my $self = Perl::RT2Github->new( );
    isa_ok ($self, 'Perl::RT2Github');
    my @rt_ids = ( 125740, 200895 );
    my $expected = {
        125740 => 14836,
        200895 => undef,
    };
    my $got = $self->get_github_ids( @rt_ids );
    is_deeply($got, $expected, "Got expected github ID for valid RT and one undef for invalid");
}

