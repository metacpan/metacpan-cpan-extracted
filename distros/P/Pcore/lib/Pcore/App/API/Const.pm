package Pcore::App::API::Const;

use Pcore -const, -export;

our $EXPORT = {
    ROOT_USER       => [qw[$ROOT_USER_NAME $ROOT_USER_ID]],
    PERMS           => [qw[$PERMS_ANY $PERMS_AUTHENTICATED]],
    TOKEN_TYPE      => [qw[$TOKEN_TYPE_PASSWORD $TOKEN_TYPE_TOKEN $TOKEN_TYPE_SESSION $TOKEN_TYPE_EMAIL_CONFIRM $TOKEN_TYPE_PASSWORD_RECOVERY]],
    INVALIDATE_TYPE => [qw[$INVALIDATE_USER $INVALIDATE_TOKEN $INVALIDATE_ALL]],
    PRIVATE_TOKEN   => [qw[$PRIVATE_TOKEN_ID $PRIVATE_TOKEN_HASH $PRIVATE_TOKEN_TYPE]],
};

const our $ROOT_USER_NAME => 'root';
const our $ROOT_USER_ID   => 1;

const our $PERMS_ANY           => undef;
const our $PERMS_AUTHENTICATED => '*';

const our $TOKEN_TYPE_PASSWORD          => 1;
const our $TOKEN_TYPE_TOKEN             => 2;
const our $TOKEN_TYPE_SESSION           => 3;
const our $TOKEN_TYPE_EMAIL_CONFIRM     => 4;
const our $TOKEN_TYPE_PASSWORD_RECOVERY => 5;

const our $INVALIDATE_USER  => 1;
const our $INVALIDATE_TOKEN => 2;
const our $INVALIDATE_ALL   => 3;

const our $PRIVATE_TOKEN_ID   => 0;
const our $PRIVATE_TOKEN_HASH => 1;
const our $PRIVATE_TOKEN_TYPE => 2;

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Const

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
