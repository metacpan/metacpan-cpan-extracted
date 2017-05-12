
INSERT INTO aus_password_crypt
    (id, class)
    VALUES ('None', 'Schema::RDBMS::AUS::Crypt::None');

INSERT INTO aus_password_crypt
    (id, class)
    VALUES ('MD5', 'Schema::RDBMS::AUS::Crypt::MD5');
    
INSERT INTO aus_password_crypt
    (id, class)
    VALUES ('SHA1', 'Schema::RDBMS::AUS::Crypt::SHA1');
