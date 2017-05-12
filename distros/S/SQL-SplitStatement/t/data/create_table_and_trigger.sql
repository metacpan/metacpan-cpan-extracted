DROP TRIGGER IF EXISTS user_change_password;
DELIMITER //
CREATE TRIGGER user_change_password AFTER UPDATE ON user
FOR EACH ROW my_block: BEGIN
    IF NEW.password != OLD.password THEN
        UPDATE user_authentication_results AS uar
        SET password_changed = 1
        WHERE uar.user_id = NEW.user_id;
    END IF;
END my_block;
set localvariable datatype;
set localvariable = parameter2;
select fields from table where field1 = parameter1;
//
delimiter ;
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);
CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
);