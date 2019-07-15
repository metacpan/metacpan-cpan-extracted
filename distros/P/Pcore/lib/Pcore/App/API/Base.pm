package Pcore::App::API::Base;

use Pcore -class;

has app => ( required => 1 );    # ConsumerOf ['Pcore::App']
has api => ( required => 1 );    # ConsumerOf ['Pcore::App::API']
has dbh => ( required => 1 );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Base

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
