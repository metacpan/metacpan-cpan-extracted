package Pcore::API::SCM::Const;

use Pcore -const, -export;

our $EXPORT = {
    SCM_TYPE     => [qw[$SCM_TYPE_HG $SCM_TYPE_GIT]],
    SCM_URL_TYPE => [qw[$SCM_URL_TYPE_SSH $SCM_URL_TYPE_HTTPS $SCM_URL_TYPE_FILE]],
    SCM_HOSTING  => [qw[$SCM_HOSTING_BITBUCKET $SCM_HOSTING_GITHUB $SCM_HOSTING_HOST]],
};

const our $SCM_TYPE_HG  => 'hg';
const our $SCM_TYPE_GIT => 'git';

const our $SCM_URL_TYPE_SSH   => 'ssh';
const our $SCM_URL_TYPE_HTTPS => 'https';

const our $SCM_HOSTING_BITBUCKET => 'bitbucket';
const our $SCM_HOSTING_GITHUB    => 'github';

const our $SCM_HOSTING_HOST => {
    $SCM_HOSTING_BITBUCKET => 'bitbucket.org',
    $SCM_HOSTING_GITHUB    => 'github.com',
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Const

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
