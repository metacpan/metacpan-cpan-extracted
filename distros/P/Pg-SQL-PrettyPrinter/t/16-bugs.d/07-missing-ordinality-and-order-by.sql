select string_agg('\U' || lpad(to_hex(ascii(unnest)), 8, '0'), '' order by ordinality) from unnest(regexp_split_to_array($1, '')) with ordinality
