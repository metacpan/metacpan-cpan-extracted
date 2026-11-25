# DBIx::Class / DBIO result classes — Getty house rules

- **Columns via `DBIx::Class::Candy` or `DBIO::Candy`** — `primary_column` / `column` macros, never `__PACKAGE__->add_column(...)`.
- **`keep_storage_value => 1`** on enum and integer columns that must not be inflated/deflated.
- **`\'NOW()'`** (literal scalar ref) for DB-side timestamp defaults.
- **Serialized columns are deterministic:** `serializer_options => { canonical => 1 }`.
- **A Moose class extending DBIx::Class** (`MooseX::NonMoose`) uses `use MooseX::MarkAsMethods autoclean => 1;` instead of `namespace::autoclean` — it keeps the overloads DBIC needs.
