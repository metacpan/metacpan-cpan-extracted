package Statocles::Command::status;
our $VERSION = '0.097';
# ABSTRACT: Show status information for the site

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my $status = $self->_get_status;
    if ($status->{last_deploy_date}) {
        say "Last deployed on " .
            DateTime::Moonpig->from_epoch(
                epoch => $status->{last_deploy_date},
            )->strftime("%Y-%m-%d at %H:%M");
        say "Deployed up to date " .
            ( $status->{last_deploy_args}{date} || '-' );
    }
    else {
        say "Never been deployed";
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command::status - Show status information for the site

=head1 VERSION

version 0.097

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
