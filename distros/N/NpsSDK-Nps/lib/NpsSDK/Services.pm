package NpsSDK::Services;

our $VERSION = '1.91'; # VERSION

our $PAY_ONLINE_2P = "PayOnLine_2p";
our $AUTHORIZE_2P = "Authorize_2p";
our $QUERY_TXS = "QueryTxs";
our $SIMPLE_QUERY_TX = "SimpleQueryTx";
our $REFUND = "Refund";
our $CAPTURE = "Capture";
our $AUTHORIZE_3P = "Authorize_3p";
our $BANK_PAYMENT_3P = "BankPayment_3p";
our $CASH_PAYMENT_3P = "CashPayment_3p";
our $CHANGE_SECRET_KEY = "ChangeSecretKey";
our $FRAUD_SCREENING = "FraudScreening";
our $NOTIFY_FRAUD_SCREENING_REVIEW = "NotifyFraudScreeningReview";
our $PAY_ONLINE_3P = "PayOnLine_3p";
our $SPLIT_AUTHORIZE_3P = "SplitAuthorize_3p";
our $SPLIT_PAY_ONLINE_3P = "SplitPayOnLine_3p";
our $BANK_PAYMENT_2P = "BankPayment_2p";
our $SPLIT_PAY_ONLINE_2P = "SplitPayOnLine_2p";
our $SPLIT_AUTHORIZE_2P = "SplitAuthorize_2p";
our $QUERY_CARD_NUMBER = "QueryCardNumber";
our $QUERY_CARD_DETAILS = "QueryCardDetails";
our $GET_IIN_DETAILS = "GetIINDetails";

our $CREATE_PAYMENT_METHOD = "CreatePaymentMethod";
our $CREATE_PAYMENT_METHOD_FROM_PAYMENT = "CreatePaymentMethodFromPayment";
our $RETRIEVE_PAYMENT_METHOD = "RetrievePaymentMethod";
our $UPDATE_PAYMENT_METHOD = "UpdatePaymentMethod";
our $DELETE_PAYMENT_METHOD = "DeletePaymentMethod";
our $CREATE_CUSTOMER = "CreateCustomer";
our $RETRIEVE_CUSTOMER = "RetrieveCustomer";
our $UPDATE_CUSTOMER = "UpdateCustomer";
our $DELETE_CUSTOMER = "DeleteCustomer";
our $RECACHE_PAYMENT_METHOD_TOKEN = "RecachePaymentMethodToken";
our $CREATE_PAYMENT_METHOD_TOKEN = "CreatePaymentMethodToken";
our $RETRIEVE_PAYMENT_METHOD_TOKEN = "RetrievePaymentMethodToken";
our $CREATE_CLIENT_SESSION = "CreateClientSession";
our $GET_INSTALLMENTS_OPTIONS = "GetInstallmentsOptions";

our @get_merch_det_not_add_services = ($QUERY_TXS,
                                       $REFUND,
                                       $SIMPLE_QUERY_TX,
                                       $CAPTURE,
                                       $CHANGE_SECRET_KEY,
                                       $NOTIFY_FRAUD_SCREENING_REVIEW,
                                       $GET_IIN_DETAILS,
                                       $QUERY_CARD_NUMBER,
                                       $CREATE_PAYMENT_METHOD,
                                       $CREATE_PAYMENT_METHOD_FROM_PAYMENT,
                                       $RETRIEVE_PAYMENT_METHOD,
                                       $UPDATE_PAYMENT_METHOD,
                                       $DELETE_PAYMENT_METHOD,
                                       $CREATE_CUSTOMER,
                                       $RETRIEVE_CUSTOMER,
                                       $UPDATE_CUSTOMER,
                                       $DELETE_CUSTOMER,
                                       $RECACHE_PAYMENT_METHOD_TOKEN,
                                       $CREATE_PAYMENT_METHOD_TOKEN,
                                       $RETRIEVE_PAYMENT_METHOD_TOKEN,
                                       $CREATE_CLIENT_SESSION,
                                       $GET_INSTALLMENTS_OPTIONS,
                                       $QUERY_CARD_DETAILS);

1;