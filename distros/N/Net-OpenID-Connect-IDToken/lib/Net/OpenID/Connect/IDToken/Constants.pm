package Net::OpenID::Connect::IDToken::Constants;
use strict;
use warnings;

use parent qw/Exporter/;

our @EXPORT;

use Exporter::Constants (
    \@EXPORT => {
        ERROR_IDTOKEN_INVALID_ALGORITHM    => "error_idtoken_invalid_algorithm",
        ERROR_IDTOKEN_TOKEN_HASH_NOT_FOUND => "error_idtoken_token_hash_not_found",
        ERROR_IDTOKEN_TOKEN_HASH_INVALID   => "error_idtoken_token_hash_invalid",
        ERROR_IDTOKEN_CODE_HASH_NOT_FOUND  => "error_idtoken_code_hash_not_found",
        ERROR_IDTOKEN_CODE_HASH_INVALID    => "error_idtoken_code_hash_invalid",
    },
);

1;
