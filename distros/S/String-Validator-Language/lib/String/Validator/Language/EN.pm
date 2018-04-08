package String::Validator::Language::EN;
$String::Validator::Language::EN::VERSION = '2.00';
sub new {
    return {
        common_strings_not_match => "Strings don\'t match.",
        common_tooshort          => "Does not meet requirement: Min Length ",
        common_toolong           => " Does not meet requirement: Max Length ",
        email_fqdn =>
            'Does not appear to contain a Fully Qualified Domain Name.',
        email_rfc822_noat => 'Missing @ symbol',
        email_rfc822      => 'Does not look like an email address.',
        email_tld         => 'This TLD (Top Level Domain) is not recognized.',
        email_nomx1       => 'Mail Exchanger for ',
        email_nomx2 =>
            ' is missing from Public DNS. Mail cannot be delivered.',
        password_mintypes => sub {
            my $self = shift @_;
            return
                "Input contained $self->{types_found} types of character, $self->{min_types} are required.";
        },
        password_minoftype => sub {
            my ( $required, $type ) = @_;
            if ( $type eq 'num' ) { $type = 'numeric' }
            return "At least $required characters of type $type is required.";
        },
        password_typeprohibit => sub {
            my $type = shift @_;
            if ( $type eq 'num' ) { $type = 'numeric' }
            return "character type $type is prohibited.";
        },
        phonenanp_not10 => sub {
            my $D = shift;    # num1, num2, len
            return
                "Not a 10 digit Area-Number $D->{num1} .. $D->{num2} = $D->{len}.";
        },
        phonenanp_badarea => 'Invalid Number, perhaps non-existent Area Code',

    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Validator::Language::EN

=head1 VERSION

version 2.00

For Documentation of this and other String::Validator::Langauge Modules please see String::Validator::Langauge, String::Validator::Commond, and String::Validator.

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
