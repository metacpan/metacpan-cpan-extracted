# Revision history for Perl::Critic::PJCJ

## v0.1.4 - 2025-08-31

## v0.1.3-TRIAL - 2025-08-31

- Enhance use/no statement handling in RequireConsistentQuoting policy:
  - Add interpolation detection
    - Statements requiring variable interpolation follow normal rules
  - Add support for `no` statements
  - Add fat comma (=>) detection
    - Statements with hash-style arguments have no parentheses
  - Add complex expression detection
    - Statements with variables, conditionals, etc. have no parentheses
    - Add version number exemption
- Improve single quote and q() handling

## v0.1.2 - 2025-07-26

- Initial release
- Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting policy
- Perl::Critic::Policy::CodeLayout::ProhibitLongLines policy
