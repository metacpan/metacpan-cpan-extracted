package Morpheus::Plugin::DB;
{
  $Morpheus::Plugin::DB::VERSION = '0.46';
}
use strict;

# ABSTRACT: plugin reading configs from SQL DB

use base qw(Morpheus::Plugin::Content);

use DBI;
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my $params = validate(@_, {
        table => { default => "Morpheus" },
        key => { default => "Name" },
        value => { default => "Config" },
        db => { type => CODEREF },
    });
    @{$self}{keys %$params} = (values %$params);
    return $self;
};

sub content ($$) {
    my ($self, $token) = @_;

    my $dbh = $self->{db}->();
    
    my ($content) = $dbh->selectrow_array(qq#
        select `$self->{value}` from `$self->{table}`
        where `$self->{key}` = ?
    #, undef, $token);
    return $content;
}

sub list ($$) {
    my ($self, $main_ns) = @_;

    #return () if $main_ns ge "/morpheus/";
    #return () if $main_ns ge "/libyandex-db-perl/"; #KILLMEPLZ!!

    my $dbh = $self->{db}->();
    return () unless $dbh;

    $main_ns = "$main_ns";
    $main_ns =~ s#^/##; #FIXME: absolute keys!

    my $pattern = $main_ns;
    $pattern =~ s/([_%\\])/\\$1/g;

    my @prefix;
    my $ns = $main_ns;
    while ($ns) {
        push @prefix, $ns;
        $ns =~ s{/?[^/]+$}{};
    }
    push @prefix, "";

    my @list = @{$dbh->selectcol_arrayref(qq#
        select `$self->{key}` from `$self->{table}`
        where `$self->{key}` like ? or `$self->{key}` in (#. join (",", ("?") x @prefix) .qq#)
    #, undef, "$pattern/%", @prefix)};

    return map { ($_ => $_) } sort { length $b <=> length $a } @list;
}

1;

__END__
=pod

=head1 NAME

Morpheus::Plugin::DB - plugin reading configs from SQL DB

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

