package Mojolicious::Plugin::Vparam::Vsort;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common;

sub register {
    my ($class, $self, $app, $conf) = @_;

    # Same as vparams but add standart table sort parameters for:
    # ORDER BY, LIMIT, OFFSET
    $app->helper(vsort => sub{
        my ($self, %attr) = @_;

        my $sort = delete $attr{'-sort'};
        die 'Key "-sort" must be ArrayRef'
            if defined($sort) and 'ARRAY' ne ref $sort;

        $attr{ $conf->{vsort_page} } = {
            type        => 'int',
            default     => 1,
        } if defined $conf->{vsort_page};

        $attr{ $conf->{vsort_rws} } = {
            type        => 'int',
            default     => $conf->{rows},
        } if defined $conf->{vsort_rws};

        $attr{ $conf->{vsort_oby} } = {
            type        => 'int',
            default     => 0,
            post        => sub { $sort->[ $_[1] ] or ($_[1] + 1) or 1 },
        } if defined $conf->{vsort_oby};

        $attr{ $conf->{vsort_ods} } = {
            type        => 'str',
            default     => $conf->{ods},
            post        => sub { uc $_[1] },
            regexp      => qr{^(?:asc|desc)$}i,
        } if defined $conf->{vsort_ods};

        my $result = $self->vparams( %attr );
        return wantarray ? %$result : $result;
    });

    return;
}

1;
