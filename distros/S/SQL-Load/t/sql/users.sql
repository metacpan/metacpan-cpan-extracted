-- # insert
INSERT INTO users (name, email, username, password) VALUES (?, ?, ?, ?);

-- # update
UPDATE users SET name = ?, email = ?, username = ?, password = ? WHERE id = ?;

-- # delete
DELETE FROM users WHERE id = ?;

-- # find 
SELECT * FROM users WHERE id = ?;

-- # find-all
SELECT * FROM users ORDER BY id DESC;

-- # find-by-email 
SELECT * FROM users WHERE email = ?;

-- # find-by-username 
SELECT * FROM users WHERE username = ?;
