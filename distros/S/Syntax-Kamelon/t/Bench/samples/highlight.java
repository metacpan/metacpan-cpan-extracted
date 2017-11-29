/*
 * Copyright (c) 2006 Sun Microsystems, Inc.  All rights reserved.  U.S.
 * Government Rights - Commercial software.  Government users are subject
 * to the Sun Microsystems, Inc. standard license agreement and
 * applicable provisions of the FAR and its supplements.  Use is subject
 * to license terms.
 *
 * This distribution may include materials developed by third parties.
 * Sun, Sun Microsystems, the Sun logo, Java and J2EE are trademarks
 * or registered trademarks of Sun Microsystems, Inc. in the U.S. and
 * other countries.
 *
 * Copyright (c) 2006 Sun Microsystems, Inc. Tous droits reserves.
 *
 * Droits du gouvernement americain, utilisateurs gouvernementaux - logiciel
 * commercial. Les utilisateurs gouvernementaux sont soumis au contrat de
 * licence standard de Sun Microsystems, Inc., ainsi qu'aux dispositions
 * en vigueur de la FAR (Federal Acquisition Regulations) et des
 * supplements a celles-ci.  Distribue par des licences qui en
 * restreignent l'utilisation.
 *
 * Cette distribution peut comprendre des composants developpes par des
 * tierces parties. Sun, Sun Microsystems, le logo Sun, Java et J2EE
 * sont des marques de fabrique ou des marques deposees de Sun
 * Microsystems, Inc. aux Etats-Unis et dans d'autres pays.
 */


import javax.jms.ConnectionFactory;
import javax.jms.Queue;
import javax.jms.Topic;
import javax.jms.Connection;
import javax.jms.Session;
import javax.jms.MessageProducer;
import javax.jms.MessageConsumer;
import javax.jms.TextMessage;
import javax.jms.JMSException;


public class SampleUtilities {
    /**
     * Waits for 'count' messages on controlQueue before
     * continuing.  Called by a publisher to make sure that
     * subscribers have started before it begins publishing
     * messages.
     *
     * If controlQueue does not exist, the method throws an
     * exception.
     *
     * @param prefix    prefix (publisher or subscriber) to be
     *                  displayed
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
     * Sends a message to controlQueue.  Called by a subscriber
     * to notify a publisher that it is ready to receive
     * messages.
     * <p>
     * If controlQueue doesn't exist, the method throws an
     * exception.
     *
     * @param prefix    prefix (publisher or subscriber) to be
     *                  displayed
     * @param controlQueue  control queue
     */
    public static void sendSynchronizeMessage(String prefix,
        ConnectionFactory connectionFactory, Queue controlQueue)
        throws Exception {
        Connection connection = null;
        Session session = null;
        MessageProducer producer = null;
        TextMessage message = null;

        try {
            connection = connectionFactory.createConnection();
            session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
        } catch (Exception e) {
            System.err.println("sendSynchronizeMessage connection problem: " +
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
            producer = session.createProducer(controlQueue);
            message = session.createTextMessage();
            message.setText("synchronize");
            System.out.println(prefix + "Sending synchronize message to " +
                "control queue");
            producer.send(message);
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
