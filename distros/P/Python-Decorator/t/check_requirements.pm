eval "use PPI"; plan skip_all => "missing module 'PPI'" if ($@);
eval "use Filter::Util::Call"; plan skip_all => "missing module 'Filter::Util::Call'" if ($@);

1;
