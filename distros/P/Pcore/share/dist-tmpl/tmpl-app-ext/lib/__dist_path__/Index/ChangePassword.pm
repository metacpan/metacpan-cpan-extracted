package Lcom::Index::ChangePassword;

use Pcore -class, -l10n => 'Lcom';

has ext_app => ( is => 'ro', isa => Str, default => 'ChangePassword', init_arg => undef );
has ext_app_title => ( is => 'ro', isa => Str, default => l10n('Change Password'), init_arg => undef );

with qw[Pcore::App::Controller::Ext];

has '+ext_default_locale' => ( default => 'ru' );
has '+path' => ( is => 'ro', isa => Str, default => '/change-password/', init_arg => undef );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Lcom::Index::ChangePassword

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
