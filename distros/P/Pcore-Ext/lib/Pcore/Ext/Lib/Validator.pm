package Pcore::Ext::Lib::Validator;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_username : Extend('Ext.data.validator.Validator') : Type('data.validator') {
    return {
        msg => l10n('Accepted characters: A-z (case-insensitive), 0-9 and underscores, length: 3-32 characters, not number'),

        validate => func ['val'],
        <<"JS",
            if (val === undefined || val === null) return '' + this.msg;

            if (val.length < 3 || val.length > 32) return '' + this.msg;

            // digits only
            var re1 = /^\\d+\$/;
            if (re1.test(val)) return '' + this.msg;

            // allowed chars
            var re2 = /[^A-Za-z0-9_]/;
            if (re2.test(val)) return '' + this.msg;

            return true;
JS
    };
}

sub EXT_telegram_username : Extend('Ext.data.validator.Validator') : Type('data.validator') {
    return {
        msg => l10n('Accepted characters: A-z (case-insensitive), 0-9 and underscores, length: 5-32 characters'),

        validate => func ['val'],
        <<"JS",
            if (val === undefined || val === null) return '' + this.msg;

            if (val.length < 5 || val.length > 32) return '' + this.msg;

            // allowed chars
            var re2 = /[^A-Za-z0-9_]/;
            if (re2.test(val)) return '' + this.msg;

            return true;
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Validator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
