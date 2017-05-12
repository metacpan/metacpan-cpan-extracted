use MsgQ::ReceiveQueue;
$rq = new MsgQ::ReceiveQueue;
$rq->start_queue("./ReceiveQueue.conf");

