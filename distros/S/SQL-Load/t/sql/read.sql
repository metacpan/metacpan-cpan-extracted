-- # find
SELECT * FROM users WHERE id = ?;

-- (find-all)
SELECT * FROM users ORDER BY id;

-- [ find-by-name ]
SELECT * FROM users WHERE name = ?;
