/*
 * Copyright (c) 2006 Sun Microsystems, Inc.  All rights reserved.  U.S.
 * Government Rights - Commercial software.  Government users are subject
 * sont des marques de fabrique ou des marques deposees de Sun
 * Microsystems, Inc. aux Etats-Unis et dans d'autres pays.
 */


import javax.jms.ConnectionFactory;
import javax.jms.Queue;
import javax.jms.JMSException;


public class SampleUtilities {
    /**
     * Waits for 'count' messages on controlQueue before
     * @param controlQueue   control queue
     * @param count     number of messages to receive
     */
    public static void receiveSynchronizeMessages(String prefix,
        ConnectionFactory connectionFactory, Queue controlQueue, int count)
        throws Exception {
        Connection connection = null;
        Session session = null;
        MessageConsumer receiver = null;

        try {
            connection = connectionFactory.createConnection();
            session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
            connection.start();
        } catch (Exception e) {
            System.err.println(
                "receiveSynchronizeMessages connection problem: " +
                e.toString());
            e.printStackTrace();

            if (connection != null) {
                try {
                    connection.close();
                } catch (JMSException ee) {
                }
            }

            throw e;
        }

        try {
            System.out.println(prefix + "Receiving synchronize messages from " +
                "control queue; count = " + count);
            receiver = session.createConsumer(controlQueue);

            while (count > 0) {
                receiver.receive();
                count--;
                System.out.println(prefix + "Received synchronize message; " +
                    " expect " + count + " more");
            }
        } catch (JMSException e) {
            System.err.println("Exception occurred: " + e.toString());
            throw e;
        } finally {
            if (connection != null) {
                try {
                    connection.close();
                } catch (JMSException e) {
                }
            }
        }
    }


    /**
     * Monitor class for asynchronous examples.  Producer signals
     * end of message stream; listener calls allDone() to notify
     * consumer that the signal has arrived, while consumer calls
     * waitTillDone() to wait for this notification.
     */
    static public class DoneLatch {
        boolean done = false;

        /**
         * Waits until done is set to true.
         */
        public void waitTillDone() {
            synchronized (this) {
                while (!done) {
                    try {
                        this.wait();
                    } catch (InterruptedException ie) {
                    }
                }
            }
        }

        /**
         * Sets done to true.
         */
        public void allDone() {
            synchronized (this) {
                done = true;
                this.notify();
            }
        }
    }
}
