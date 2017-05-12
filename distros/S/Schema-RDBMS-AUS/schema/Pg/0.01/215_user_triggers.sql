
CREATE TRIGGER aus_user_on_insert
    AFTER INSERT
    ON aus_user
    FOR EACH ROW
    EXECUTE PROCEDURE aus_user_insert ()
;

CREATE TRIGGER aus_user_on_delete
    BEFORE DELETE
    ON aus_user
    FOR EACH ROW
    EXECUTE PROCEDURE aus_user_delete ()
;

CREATE TRIGGER aus_user_on_update
    AFTER UPDATE
    ON aus_user
    FOR EACH ROW
    EXECUTE PROCEDURE aus_user_update ()
;
