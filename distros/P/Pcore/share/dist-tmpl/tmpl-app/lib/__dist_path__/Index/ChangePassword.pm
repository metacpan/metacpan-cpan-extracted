package Lcom::Index::ChangePassword;

use Pcore -class, -l10n;

with qw[Pcore::App::Controller::Ext];

has ext_app   => 'ChangePassword';
has ext_title => l10n('Change Password');
has path      => '/change-password/', init_arg => undef;

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
