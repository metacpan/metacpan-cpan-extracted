eval {
    require Test::Arrow;
    Test::Arrow->import;
};

Test::Arrow->new->ok(!$@)
    or Test::Arrow->diag($@);

Test::Arrow->done;
