
CREATE TRIGGER aus_user_membership_on_insert
    AFTER INSERT
    ON aus_user_membership
    FOR EACH ROW
    EXECUTE PROCEDURE aus_user_membership_insert ()
;

CREATE TRIGGER aus_user_membership_on_delete
    BEFORE DELETE
    ON aus_user_membership
    FOR EACH ROW
    EXECUTE PROCEDURE aus_user_membership_delete ()
;
