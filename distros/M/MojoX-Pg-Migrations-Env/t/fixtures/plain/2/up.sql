create function add_tax(numeric) returns numeric as $$
  select $1 * 1.25;
$$ language sql;
